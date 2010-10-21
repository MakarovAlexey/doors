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
;;; DEALINGS IN THE SOFTWARE.

(asdf:defsystem #:doors
  :version "0.0.1"
  :description "Doors, a lisper's gateway to Windows"
  :author "Dmitry Ignatiev <lovesan.ru@gmail.com>"
  :maintainer "Dmitry Ignatiev <lovesan.ru@gmail.com>"
  :licence "MIT"
  :depends-on (#:trivial-features #:alexandria #:virgil #:trivial-garbage #:closer-mop)
  :serial t
  :components ((:module "winapi"
                        :serial t
                        :components ((:file "package")
                                     (:file "libraries")
                                     (:file "features")
                                     (:file "wintypes")
                                     (:file "hresult")
                                     (:file "winerror")
                                     (:file "osversion")
                                     (:file "uuid")
                                     (:file "winnt")
                                     (:file "winbase")
                                     ))
               (:module "com"
                        :serial t
                        :components ((:file "package")
                                     (:file "interface")
                                     (:file "interface-defs")
                                     (:file "object")
                                     (:file "unknown")
                                     ))))

;; vim: ft=lisp et
