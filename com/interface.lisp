;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-

;;; Copyright (C) 2010-2011, Dmitry Ignatiev <lovesan.ru@gmail.com>

;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:

;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.

;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE

(in-package #:doors.com)

(defvar *pointer-to-object-mapping* (make-weak-hash-table :test #'eql
                                      :weakness :value))

(defvar *pointer-to-interface-mapping* (make-weak-hash-table :test #'equal
                                         :weakness :value))

(defvar *iid-to-interface-class-mapping* (make-weak-hash-table :test #'equalp
                                           :weakness :value))

(defvar *global-interface-table* nil)

(defvar *registered-interfaces* '())

(defvar *mta-post-mortem-thread* nil)
(defvar *mta-post-mortem-lock* nil)
(defvar *mta-post-mortem-condvar* nil)
(defvar *mta-post-mortem-queue* '())

(eval-when (:compile-toplevel :load-toplevel :execute)

(closer-mop:defclass com-interface-class (standard-class)
  ((%iid :initform nil :initarg :iid)
   (vtable-name :initform nil
                :initarg :vtable-name
                :reader com-interface-class-vtable-name)
   (wrapper-functions
     :initform (make-hash-table :test #'equal)
     :accessor %interface-class-wrapper-functions)
   (methods :initform '()
            :initarg :methods
            :reader com-interface-class-methods)))

(closer-mop:defmethod closer-mop:validate-superclass
    ((class standard-class) (superclass com-interface-class))
  nil)

(closer-mop:defmethod closer-mop:validate-superclass
    ((class com-interface-class) (superclass standard-class))
  t)
  
(closer-mop:defclass com-interface ()
  ((com-pointer :initform &0 :initarg :pointer)
   (%token :initform (cons nil nil))) ;;(is IUnknown? . GIT token)
  (:metaclass com-interface-class))
  
(closer-mop:defmethod change-class ((object com-interface) new-class &rest initargs)
  (declare (ignore initargs))
  (error "You can not change class of existing COM interface wrapper"))
  
(closer-mop:defclass com-wrapper ()
  ((%token :initform (cons nil nil) :accessor %com-wrapper-token :type cons)
   (%wrapper-interface-pointers
     :accessor %wrapper-interface-pointers)
   (%context-flags :initarg :context
                   :reader com-wrapper-context)
   (%server-info :initarg :server-info
                 :reader com-wrapper-server-info))
  (:default-initargs :context :all :server-info nil))
  
(closer-mop:defmethod change-class
    ((object com-wrapper) new-class &rest initargs)
  (declare (ignore new-class initargs))
  (error "You can not change class of existing COM wrapper"))
  
(closer-mop:defmethod reinitialize-instance
    ((object com-wrapper) &rest initargs &key &allow-other-keys)
  (declare (ignore initargs))
  (error "You can not reinitialize instance of COM wrapper"))
  
(closer-mop:defclass com-generic-function (closer-mop:standard-generic-function)
  ()
  (:metaclass closer-mop:funcallable-standard-class))
  
(closer-mop:defmethod no-applicable-method
    ((function com-generic-function) &rest args)
  (declare (ignore args))
  (error 'com-error :code error-not-implemented))
  
(closer-mop:finalize-inheritance (find-class 'com-interface-class))
(closer-mop:finalize-inheritance (find-class 'com-interface))
(closer-mop:finalize-inheritance (find-class 'com-wrapper))
(closer-mop:finalize-inheritance (find-class 'com-generic-function))
  
) ;;eval-when

(deftype iid () '(or symbol com-interface-class guid))

(defun find-interface-class (name &optional (errorp T))
  (declare (type (or symbol guid) name))
  (let ((class (etypecase name
                 (symbol (find-class name nil))
                 (guid (gethash name *iid-to-interface-class-mapping*)))))
    (if (typep class 'com-interface-class)
      class
      (and errorp (error 'com-error :code error-no-interface)))))

(defconstant pointer-slot-location
    (closer-mop:slot-definition-location
        (find 'com-pointer
              (closer-mop:class-slots (find-class 'com-interface))
              :key #'closer-mop:slot-definition-name)))

(declaim (inline com-interface-pointer))
(defun com-interface-pointer (interface)
  (declare (type com-interface interface))
  (the pointer (closer-mop:standard-instance-access interface pointer-slot-location)))

(declaim (inline com-interface-method-pointer))
(defun com-interface-method-pointer (interface method-name)
  (declare (type com-interface interface)
           (type symbol method-name))
  (let* ((class (class-of interface))
         (index (or (position method-name
                              (com-interface-class-methods class)
                              :test #'eq)
                    (error "Interface ~s has no method named ~s"
                           (class-name class) method-name))))
    (the pointer (deref (deref (com-interface-pointer interface) 'pointer)
                        'pointer
                        (* index (sizeof 'pointer))))))

(defconstant token-slot-location
    (closer-mop:slot-definition-location
        (find '%token
              (closer-mop:class-slots (find-class 'com-interface))
              :key #'closer-mop:slot-definition-name)))

(declaim (inline %com-interface-token))
(defun %com-interface-token (interface)
  (declare (type com-interface interface))
  (the cons (closer-mop:standard-instance-access interface token-slot-location)))

(defmethod uuid-of ((class com-interface-class))
  (slot-value class '%iid))

(declaim (inline %release))
(defun %release (pointer)
  (declare (type pointer pointer))
  (external-pointer-call
    (deref (&+ (deref pointer '*) 2 '*) '*)
    ((:stdcall)
     (ulong)
     (pointer this :aux pointer))))

(defun %apartment-type ()
  (let ((context (external-function-call
                   "CoGetContextToken"
                   ((:stdcall ole32)
                    (dword rv (if (zerop rv) context nil))
                    ((& pointer :out) context :aux))))
        ;;IID_IComThreadingInfo:
        (%info-iid (load-time-value
                     (guid #x000001CE #x0000 #x0000
                           #xC0 #x00 #x00 #x00 #x00 #x00 #x00 #x46)
                     t)))
    (declare (dynamic-extent %info-iid))
    (when context
      (let ((info (external-pointer-call
                    (deref (deref context '*) '*) ;;QueryInterface
                    ((:stdcall)
                     (dword rv (if (zerop rv)
                                 info
                                 nil))
                     (pointer this :aux context)
                     ((& guid) iid :aux %info-iid)
                     ((& pointer :out) info :aux)))))
        (when info
          (unwind-protect
              (external-pointer-call
                (deref (&+ (deref info '*) 3 '*) '*)
                ((:stdcall)
                 (dword rv (if (zerop rv)
                             (case type
                               ((0 3) :sta)
                               (1 :mta)
                               (2 :na))
                             nil))
                 (pointer this :aux info)
                 ((& dword :out) type :aux)))
            (%release info)))))))

(declaim (inline %add-to-git))
(defun %add-to-git (pointer)
  (declare (type pointer pointer))
  (prog1 (external-pointer-call
           (deref (&+ (deref *global-interface-table* '*) 3 '*) '*)
           ((:stdcall)
            (hresult rv cookie)
            (pointer this :aux *global-interface-table*)
            (pointer unknown :aux pointer)
            ((& guid) iid :aux (load-time-value
                                 (guid #x00000000 #x0000 #x0000
                                       #xC0 #x00 #x00 #x00 #x00 #x00 #x00 #x46)
                                 t))
            ((& dword :out) cookie :aux)))
   (%release pointer)))

(declaim (inline %revoke-from-git))
(defun %revoke-from-git (cookie)
  (declare (type dword cookie))
  (external-pointer-call
    (deref (&+ (deref *global-interface-table* '*) 4 '*) '*)
    ((:stdcall)
     (dword rv (zerop rv))
     (pointer this :aux *global-interface-table*)
     (dword cookie :aux cookie))))

(defun translate-interface (pointer class &optional add-ref)
  (declare (type pointer pointer)
           (type (or symbol guid com-interface-class) class)
           (optimize (speed 3)))
  (unless (typep class 'com-interface-class)
    (setf class (find-interface-class class)))
  (if (&? pointer)
    (let* ((address (the size-t (&& pointer)))
           (typed-pointer (cons address class))
           (interface (the com-interface
                           (or (gethash typed-pointer *pointer-to-interface-mapping*)
                               (setf (gethash typed-pointer *pointer-to-interface-mapping*)
                                     (make-instance class :pointer pointer)))))
           (token (the cons (%com-interface-token interface))))
      (when (and add-ref (car token))
        #-thread-support
        (unless (%apartment-type)
          (external-function-call
            "CoInitialize"
            ((:stdcall ole32)
             (dword)
             (pointer reserved :aux &0))))
        (if (cdr token)
          (%release pointer)
          (setf (cdr token) (%add-to-git pointer))))
      interface)
    nil))

(declaim (inline convert-interface))
(defun convert-interface (interface)
  (declare (type (or null com-interface) interface))
  (if (null interface)
    &0
    (com-interface-pointer interface)))

(define-immediate-type com-interface-type ()
  ((name :initform nil
         :initarg :name
         :reader com-interface-type-name)
   (add-ref :initform nil :initarg :add-ref
             :reader com-interface-type-add-ref-p))
  (:base-type pointer)
  (:lisp-type (type) `(or null ,(com-interface-type-name type) com-object com-wrapper))
  (:prototype (type) nil)
  (:prototype-expansion (type) nil)
  (:translator (pointer type)
    (translate-interface pointer
                         (find-interface-class (com-interface-type-name type))
                         (com-interface-type-add-ref-p type)))
  (:converter-expansion (value type)
    (once-only (value)
      `(etypecase ,value
         (null &0)
         (com-interface (com-interface-pointer ,value))
         (com-wrapper (or (gethash ',(com-interface-type-name type)
                                   (%wrapper-interface-pointers ,value))
                          (error 'com-error :code error-no-interface)))
         (com-object  (prog1
                       (com-interface-pointer
                         (acquire-interface
                           ,value ',(com-interface-type-name type)))
                       (release ,value))))))
  (:translator-expansion (pointer-form type)
    `(translate-interface ,pointer-form
                          (find-interface-class
                            ',(com-interface-type-name type))
                          ,(and (com-interface-type-add-ref-p type)
                                T)))
  (:allocator-expansion (value type)
    `(alloc 'pointer))
  (:deallocator-expansion (pointer type)
    `(free ,pointer '*))
  (:cleaner-expansion (pointer value type)
    nil))

(defmethod unparse-type ((type com-interface-type))
  (com-interface-type-name type))

(define-translatable-type iid-type ()
  ()
  (:simple-parser iid)
  (:lisp-type (type) 'iid)
  (:prototype (type) (guid 0 0 0 0 0 0 0 0 0 0 0))
  (:prototype-expansion (type) '(guid 0 0 0 0 0 0 0 0 0 0 0))
  (:fixed-size (type) (sizeof 'guid))
  (:cleaner (value pointer type) nil)
  (:cleaner-expansion (value pointer type) nil)
  (:allocator (value type) (alloc 'guid))
  (:allocator-expansion (value type) `(alloc 'guid))
  (:deallocator (pointer type) (free pointer 'guid))
  (:deallocator-expansion (pointer type) `(free ,pointer 'guid))
  (:reader (pointer out type)
    (let ((guid (or (and (typep out 'guid) out)
                    (prototype type))))
      (or (find-interface-class (deref pointer 'guid 0 guid) nil)
          guid)))
  (:reader-expansion (pointer out type)
    (once-only ((pointer `(the pointer ,pointer))
                (out `(the iid ,out)))
      (with-gensyms (guid)
        `(let ((,guid (or (and (guidp ,out) ,out)
                          ,(expand-prototype type))))
           (declare (type guid ,guid))
           (or (find-interface-class (deref ,pointer 'guid 0 ,guid) nil)
               ,guid)))))
  (:writer (value pointer type)
    (let* ((class (if (typep value 'com-interface-class)
                    value
                    (find-interface-class value)))
           (guid (or (slot-value class '%iid)
                     (error 'com-error :code error-no-interface))))
      (setf (deref pointer 'guid) guid)
      value))
  (:writer-expansion (value pointer type)
    (once-only (value (pointer `(the pointer ,pointer)))
      (with-gensyms (class guid)
        `(let* ((,class (the com-interface-class
                             (if (typep ,value 'com-interface-class)
                               ,value
                               (find-interface-class ,value))))
                (,guid (or (slot-value ,class '%iid)
                           (error 'com-error :code error-no-interface))))
           (setf (deref ,pointer 'guid) (the guid ,guid))
           ,value)))))

(declaim (inline %current-tid))
(defun %current-tid ()
  (external-function-call
    "GetCurrentThreadId"
    ((:stdcall kernel32)
     (dword))))

#+thread-support
(defun %mta-post-mortem-thread-function () 
  (external-function-call
    "CoInitializeEx"
    ((:stdcall ole32)
     (hresult)
     (pointer reserved :aux &0)
     (dword type :aux 0)))
  (let ((clsid-git (load-time-value
                     (guid #x00000323 #x0000 #x0000
                           #xC0 #x00 #x00 #x00 #x00 #x00 #x00 #x46)
                     t))
        (iid-git (load-time-value
                   (guid #x00000146 #x0000 #x0000
                         #xC0 #x00 #x00 #x00 #x00 #x00 #x00 #x46)
                   t)))
    (declare (dynamic-extent clsid-git iid-git))
    (setf *global-interface-table* (external-function-call
                                     "CoCreateInstance"
                                     ((:stdcall ole32)
                                      (hresult rv git)
                                      ((& guid) clsid :aux clsid-git)
                                      (pointer outer :aux &0)
                                      (dword context :aux 1) ;;CLSCTX_INPROC_SERVER
                                      ((& guid) iid :aux iid-git)
                                      ((& pointer :out) git :aux)))))
  (bt:with-lock-held (*mta-post-mortem-lock*)
    (bt:condition-notify *mta-post-mortem-condvar*))
  (bt:acquire-lock *mta-post-mortem-lock*)
  (loop
    (loop :for current = (pop *mta-post-mortem-queue*)
      :while current :do
      (destructuring-bind (function . args) current
        (apply function args)))
    (bt:condition-wait *mta-post-mortem-condvar*
                       *mta-post-mortem-lock*)))

(defun %ensure-mta-post-mortem-thread ()
  #+thread-support
  (unless (and *mta-post-mortem-thread*
               (bt:thread-alive-p *mta-post-mortem-thread*))
    (setf *mta-post-mortem-queue* '()
          *mta-post-mortem-lock* (bt:make-lock "COM MTA post-mortem thread's lock")
          *mta-post-mortem-condvar* (bt:make-condition-variable))
    (bt:acquire-lock *mta-post-mortem-lock*)
    (setf *mta-post-mortem-thread* (bt:make-thread #'%mta-post-mortem-thread-function
                                     :name "COM MTA post-mortem thread"))
    (bt:condition-wait *mta-post-mortem-condvar*
                       *mta-post-mortem-lock*)
    (bt:release-lock *mta-post-mortem-lock*))
  #-thread-support
  (unless (%apartment-type)
    (external-function-call
      "CoInitialize"
      ((:stdcall ole32)
       (dword)
       (pointer reserved :aux &0))))
  #-thread-support
  (let ((clsid-git (load-time-value
                     (guid #x00000323 #x0000 #x0000
                           #xC0 #x00 #x00 #x00 #x00 #x00 #x00 #x46)
                     t))
        (iid-git (load-time-value
                   (guid #x00000146 #x0000 #x0000
                         #xC0 #x00 #x00 #x00 #x00 #x00 #x00 #x46)
                   t)))
    (declare (dynamic-extent clsid-git iid-git))
    (setf *global-interface-table* (external-function-call
                                     "CoCreateInstance"
                                     ((:stdcall ole32)
                                      (hresult rv git)
                                      ((& guid) clsid :aux clsid-git)
                                      (pointer outer :aux &0)
                                      (dword context :aux 1) ;;CLSCTX_INPROC_SERVER
                                      ((& guid) iid :aux iid-git)
                                      ((& pointer :out) git :aux)))))
  (values))

(%ensure-mta-post-mortem-thread)
