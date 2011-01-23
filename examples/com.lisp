;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-

;;; Copyright (C) 2010, Dmitry Ignatiev <lovesan.ru@gmail.com>

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

(in-package #:doors.com.examples)

(closer-mop:defclass factory-class (com-class)
  ((locked :initform nil))
  (:interfaces class-factory)
  (:metaclass com-class))

(closer-mop:defmethod create-instance ((class factory-class) iid &optional outer)
  (if outer
    (error 'com-error :code error-not-implemented)
    (values nil outer iid (acquire-interface (make-instance class) iid))))

(closer-mop:defmethod lock-server ((class factory-class) lock)
  (if lock
    (if (slot-value class 'locked)
      (warn 'windows-status :code status-false)
      (add-ref class))
    (if (slot-value class 'locked)
      (release class)
      (warn 'windows-status :code status-false)))
  (values nil lock))

(define-interface hello-world
    ((iid-hello-world
       #xF9210244 #x38D1 #x49C0
       #xA8 #x48 #x68 #x4E #xDD #x3D #xBF #xF0)
     unknown)
  (hello-world (hresult)
      (string (& wstring) :optional "Hello, world!")))

(closer-mop:defclass hello-world-object (com-object)
  ()
  (:metaclass factory-class)
  (:interfaces hello-world)
  (:clsid . "{DF748DA7-BCB9-4F67-8D32-F9AA1AAA3ABF}"))

(closer-mop:defmethod hello-world ((object hello-world-object)
                        &optional (string "Hello, world!"))
  (write-line string)
  (values nil string))

(defun register-server ()
  (handler-bind
    ((windows-status #'muffle-warning))
    (initialize-com))
  (register-class-object (find-class 'hello-world-object)
                         :server
                         :multiple-use))

(closer-mop:defclass hello-world-wrapper (com-wrapper)
  ()
  (:metaclass com-wrapper-class)
  (:interfaces hello-world)
  (:clsid . "{DF748DA7-BCB9-4F67-8D32-F9AA1AAA3ABF}"))
