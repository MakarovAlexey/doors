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

(in-package #:doors)

(defalias word () 'uint16)
(deftype word () 'uint16)

(defalias dword () 'uint32)
(deftype dword () 'uint32)

(defalias qword () 'uint64)
(deftype qword () 'uint64)

(defalias wparam () 'uint-ptr)
(deftype wparam () 'uint-ptr)
(defalias lparam () 'int-ptr)
(deftype lparam () 'int-ptr)
(defalias lresult () 'int-ptr)
(deftype lresult () 'int-ptr)

(defalias long-ptr () 'int-ptr)
(deftype long-ptr () 'int-ptr)
(defalias ulong-ptr () 'uint-ptr)
(deftype ulong-ptr () 'uint-ptr)

(defalias atom () 'word)
(defconstant invalid-atom 0)
(declaim (inline valid-atom-p))
(defun valid-atom-p (atom)
  (declare (type word atom))
  (not (zerop atom)))

(deftype handle () '(or null pointer))

(define-immediate-type handle-type ()
  ()
  (:simple-parser handle)
  (:base-type pointer)
  (:lisp-type (type) 'handle)
  (:prototype (type) nil)
  (:prototype-expansion (type) nil)
  (:converter (value type)
    (or value &0))
  (:translator (value type)
    (and (&? value) value))
  (:converter-expansion (value type)
    `(or ,value &0))
  (:translator-expansion (value type)
    (with-gensyms (handle)
     `(let ((,handle ,value))
        (declare (type pointer ,handle))
        (and (&? ,handle) ,handle))))
  (:allocator-expansion (value type)
    `(alloc '*))
  (:deallocator-expansion (pointer type)
    `(free ,pointer '*))
  (:cleaner-expansion (pointer value type)
    nil))

(define-symbol-macro invalid-handle-value (& #xFFFFFFFF))
(declaim (inline valid-handle-p))
(defun valid-handle-p (handle)
  (declare (type handle handle))
  (or (null handle)
      (not (&= handle invalid-handle-value))))

(defalias astring (&optional length)
  `(string :encoding :ascii
           :byte-length ,(if length
                           (* length (sizeof 'char))
                           nil)))
(defalias wstring (&optional length)
  `(string :encoding :utf-16le
           :byte-length ,(if length
                           (* length (sizeof 'wchar))
                           nil)))

(defalias tstring (&optional length)
  #+doors.unicode `(wstring ,length)
  #-doors.unicode `(astring ,length))

(defalias tchar ()
  #+doors.unicode 'wchar
  #-doors.unicode 'char)

(declaim (inline make-word))
(defun make-word (low high)
  (declare (type integer low high))
  (logior (logand low #xFF)
          (ash (logand high #xFF) 8)))

(declaim (inline make-short))
(defun make-short (low high)
  (declare (type integer low high))
  (let ((u (make-word low high)))
    (declare (type word u))
    (the int16
         (if (logbitp 15 u)
           (lognot (logand #xFFFF (lognot u)))
           u))))

(declaim (inline make-dword))
(defun make-dword (low high)
  (declare (type integer low high))
  (logand #xFFFFFFFF
          (logior (logand low #xFFFF)
                  (ash (logand high #xFFFF) 16))))

(declaim (inline make-long))
(defun make-long (low high)
  (declare (type integer low high))
  (let ((u (make-dword low high)))
    (declare (type dword u))
    (the int32
         (if (logbitp 31 u)
           (lognot (logand #xFFFFFFFF (lognot u)))
           u))))

(declaim (inline make-qword))
(defun make-qword (low high)
  (declare (type integer low high))
  (logand #xFFFFFFFFFFFFFFFF
          (logior (logand low #xFFFFFFFF)
                  (ash (logand high #xFFFFFFFF) 32))))

(declaim (inline make-long-long))
(defun make-long-long (low high)
  (declare (type integer low high))
  (let ((u (make-qword low high)))
    (declare (type qword u))
    (the int64
         (if (logbitp 63 u)
           (lognot (logand #xFFFFFFFFFFFFFFFF (lognot u)))
           u))))

(declaim (inline low-dword))
(defun low-dword (x)
  (declare (type integer x))
  (logand x #xFFFFFFFF))

(declaim (inline high-dword))
(defun high-dword (x)
  (declare (type integer x))
  (logand (ash x -32) #xFFFFFFFF))

(declaim (inline low-word))
(defun low-word (x)
  (declare (type integer x))
  (logand x #xFFFF))

(declaim (inline high-word))
(defun high-word (x)
  (declare (type integer x))
  (logand (ash x -16) #xFFFF))

(declaim (inline low-byte))
(defun low-byte (x)
  (declare (type integer x))
  (logand x #xFF))

(declaim (inline high-byte))
(defun high-byte (x)
  (declare (type integer x))
  (logand (ash x -8) #xFF))

(defconstant unicode-string-max-bytes 65534)
(defconstant unicode-string-max-chars 32767)

(define-translatable-type pascal-string-type ()
  ()
  (:simple-parser pascal-string)
  (:size (val type)
    (1+ (length val)))
  (:size-expansion (val type)
    `(1+ (length ,val)))
  (:align (type) 1)
  (:prototype (type) "")
  (:prototype-expansion (type) "")
  (:reader (ptr out type)
    (let ((len (deref ptr 'byte)))
      (read-cstring ptr :out out :byte-length len
                    :encoding :ascii
                    :offset 1)))
  (:reader-expansion (pointer out type)
    (once-only ((pointer `(the pointer ,pointer)))
      (with-gensyms (length)
        `(let ((,length (deref ,pointer 'byte)))
           (read-cstring ,pointer :out ,out :byte-length ,length
                         :encoding :ascii
                         :offset 1)))))
  (:writer (val ptr type)
    (let ((len (length val)))
      (setf (deref ptr 'byte) len)
      (write-cstring val ptr :byte-length len
                     :encoding :ascii
                     :offset 1)))
  (:writer-expansion (value pointer type)
    (once-only ((pointer `(the pointer ,pointer))
                (value `(the string ,value)))
      (with-gensyms (length)
        `(let ((,length (length ,value)))
           (setf (deref ,pointer 'byte) ,length)
           (write-cstring ,value ,pointer :byte-length ,length
                          :encoding :ascii
                          :offset 1)))))
  (:cleaner-expansion (ptr val type)
    nil)
  (:allocator-expansion (val type)
    `(raw-alloc (1+ (length ,val))))
  (:deallocator-expansion (ptr type)
    `(raw-free ,ptr)))
