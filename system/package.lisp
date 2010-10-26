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

(in-package #:cl-user)

(defpackage #:doors
  (:use #:cl #:alexandria #:virgil)
  (:export
    ;;libraries
    #:kernel32
    #:user32
    #:gdi32
    #:ws2-32
    #:advapi32
      
    ;;windows types
    #:word
    #:dword
    #:qword
    #:wparam
    #:lparam
    #:hresult
    #:lresult
    #:long-ptr
    #:ulong-ptr
    #:handle
    #:valid-handle-p
    #:invalid-handle-value
    #:hresult
    #:atom
    #:invalid-atom
    #:valid-atom-p
    #:astring
    #:wstring
    #:tstring
    #:unicode-string-max-bytes
    #:unicode-string-max-chars
    
    ;;utility functions
    #:make-short
    #:make-word
    #:make-long
    #:make-dword
    #:make-long-long
    #:make-qword
    #:low-dword
    #:high-dword
    #:low-word
    #:high-word
    #:low-byte
    #:high-byte
    
    ;;errors and conditions
    #:facility
    #:facility-null
    #:facility-rpc
    #:facility-dispatch
    #:facility-storage
    #:facility-interface
    #:facility-win32
    #:facility-windows
    #:facility-security
    #:facility-sspi
    #:facility-control
    #:facility-certification
    #:facility-internet
    #:facility-media-server
    #:facility-msmq
    #:facility-setup-api
    #:facility-smart-card
    #:facility-com+
    #:facility-aaf
    #:facility-urt
    #:facility-acs
    #:facility-direct-play
    #:facility-umi
    #:facility-sxs
    #:facility-windows-ce
    #:facility-http
    #:facility-background-copy
    #:facility-configuration
    #:facility-state-management
    #:facility-meta-directory
    #:facility-windows-update
    #:facility-directory-service

    #:make-hresult
    #:hresult-from-win32
    #:hresult-from-nt
    #:hresult-error-p
    #:hresult-facility
    #:hresult-code

    #:windows-condition
    #:windows-condition-code

    #:define-results

    #:windows-status
    #:windows-status-code

    #:status-ok
    #:status-false

    #:windows-error
    #:windows-error-code

    #:error-success
    #:error-unexpected-failure
    #:error-not-implemented
    #:error-out-of-memory
    #:error-invalid-arg
    #:error-no-interface
    #:error-invalid-pointer
    #:error-invalid-handle
    #:error-abort
    #:error-failure
    #:error-access-denied
    #:error-data-pending
    
    #:get-last-error
    #:set-last-error
    #:last-error
    #:non-system-error
    #:system-error-code-p
    #:beep
    #:capture-stack-back-trace
    #:fatal-app-exit
    #:flash-window
    #:flash-window-ex
    #:flash-window-flags
    #:flashw-stop
    #:flashw-caption
    #:flashw-tray
    #:flashw-all
    #:flashw-timer
    #:flashw-timer-no-fg
    #:flash-window-info
    #:flash-window-hwnd
    #:flash-window-count
    #:flash-window-timeout
    #:format-message
    #:format-message-flags
    #:format-message-allocate-buffer
    #:format-message-argument-array
    #:format-message-from-module
    #:format-message-from-string
    #:format-message-from-system
    #:format-message-ignore-inserts
    #:format-message-max-width-mask
    #:system-error-mode
    #:sem-fail-critical-errors
    #:sem-no-alignment-fault-exception
    #:sem-no-page-fault-error-box
    #:sem-no-open-file-error-box
    #:get-error-mode
    #:set-error-mode
    #:get-thread-error-mode
    #:set-thread-error-mode
    #:message-beep
    
    ;;winnt version
    #:get-version
    #:get-version-ex
    #:winnt-version
    #:version-suite
    #:ver-suite-backoffice
    #:ver-suite-blade
    #:ver-suite-compute-server
    #:ver-suite-datacenter
    #:ver-suite-enterprise
    #:ver-suite-embedded-nt
    #:ver-suite-personal
    #:ver-suite-single-user-ts
    #:ver-suite-small-business
    #:ver-suite-small-business-restricted
    #:ver-suite-storage-server
    #:ver-suite-terminal
    #:ver-suite-home-server
    #:ver-server-nt
    #:ver-workstation-nt
    #:version-product-type
    #:ver-nt-domain-controller
    #:ver-nt-server
    #:ver-nt-workstation
    #:os-version-info
    #:os-version-info-ex-p
    #:osverinfo-size
    #:osverinfo-major-version
    #:osverinfo-minor-version
    #:osverinfo-build-number
    #:osverinfo-platform-id
    #:osverinfo-csd-version
    #:osverinfo-service-pack-major
    #:osverinfo-service-pack-minor
    #:osverinfo-suite-mask
    #:osverinfo-product-type
    
    ;;uuid and friends
    #:uuid-of
    #:uuid-null
    #:guid-null
    #:iid-null
    #:clsid-null
    #:fmtid-null
    
    #:uuid
    #:uuid-dw
    #:uuid-w1
    #:uuid-w2
    #:uuid-b1
    #:uuid-b2
    #:uuid-b3
    #:uuid-b4
    #:uuid-b5
    #:uuid-b6
    #:uuid-b7
    #:uuid-b8
    #:uuid-p
    #:copy-uuid
    #:define-uuid
    #:define-ole-uuid
    #:with-uuid-accessors
    #:uuid-equal
    
    #:guid
    #:guid-dw
    #:guid-w1
    #:guid-w2
    #:guid-b1
    #:guid-b2
    #:guid-b3
    #:guid-b4
    #:guid-b5
    #:guid-b6
    #:guid-b7
    #:guid-b8
    #:guid-p
    #:copy-guid
    #:define-guid
    #:define-ole-guid
    #:with-guid-accessors
    #:guid-equal
    
    #:iid
    #:iid-dw
    #:iid-w1
    #:iid-w2
    #:iid-b1
    #:iid-b2
    #:iid-b3
    #:iid-b4
    #:iid-b5
    #:iid-b6
    #:iid-b7
    #:iid-b8
    #:iid-p
    #:copy-iid
    #:define-iid
    #:define-ole-iid
    #:with-iid-accessors
    #:iid-equal
    
    #:clsid
    #:clsid-dw
    #:clsid-w1
    #:clsid-w2
    #:clsid-b1
    #:clsid-b2
    #:clsid-b3
    #:clsid-b4
    #:clsid-b5
    #:clsid-b6
    #:clsid-b7
    #:clsid-b8
    #:clsid-p
    #:copy-clsid
    #:define-clsid
    #:define-ole-clsid
    #:with-clsid-accessors
    #:clsid-equal
    
    #:fmtid
    #:fmtid-dw
    #:fmtid-w1
    #:fmtid-w2
    #:fmtid-b1
    #:fmtid-b2
    #:fmtid-b3
    #:fmtid-b4
    #:fmtid-b5
    #:fmtid-b6
    #:fmtid-b7
    #:fmtid-b8
    #:fmtid-p
    #:copy-fmtid
    #:define-fmtid
    #:define-ole-fmtid
    #:with-fmtid-accessors
    #:fmtid-equal
        
    #:objectid
    #:copy-objectid
    #:objectid-p
    #:objectid-lineage
    #:objectid-uniquifier
    
    ;;security stuff
    #:security-attributes
    #:security-atributes-descriptor
    #:security-attributes-inherit-handle
    #:luid
    #:luid-low-part
    #:luid-high-part
    #:trustee
    #:trustee-name
    #:trustee-form
    #:trustee-type
    #:trustee-is-sid
    #:trustee-is-name
    #:trustee-is-bad-form
    #:trustee-is-objects-and-sid
    #:trustee-is-objects-and-name
    #:trustee-is-unknown
    #:trustee-is-user
    #:trustee-is-group
    #:trustee-is-domain
    #:trustee-is-alias
    #:trustee-is-well-known-group
    #:trustee-is-deleted
    #:trustee-is-invalid
    #:trustee-is-compute
    #:se-object-type
    #:se-unknown-object-type
    #:se-file-object
    #:se-service
    #:se-printer
    #:se-registry-key
    #:se-lmshare
    #:se-kernel-object
    #:se-window-object
    #:se-ds-object
    #:se-ds-object-all
    #:se-provider-defined-object
    #:se-wmi-guid-object
    #:se-registry-wow64-32-key
    #:objects-and-name
    #:make-objects-and-name
    #:objects-and-name
    #:objects-and-name-objects-present
    #:objects-and-name-object-type
    #:objects-and-name-object-type-name
    #:objects-and-name-inherited-object-type-name
    #:objects-and-name-name
    #:object-and-sid
    #:make-objects-and-sid
    #:objects-and-sid-objects-present
    #:objects-and-sid-object-type-guid
    #:objects-and-sid-inherited-object-type-guid
    #:objects-and-sid-sid
    
    ;;console stuff
    #:console-event
    #:event-console-caret
    #:event-console-end-application
    #:event-console-layout
    #:event-console-start-application
    #:event-console-update-region
    #:event-console-update-scroll
    #:event-console-update-simple
    #:char-attributes
    #:char-foreground-blue
    #:char-foreground-green
    #:char-foreground-red
    #:char-foreground-intensity
    #:char-background-blue
    #:char-background-green
    #:char-background-red
    #:char-background-intensity
    #:char-common-lvb-leading-byte
    #:char-common-lvb-trailing-byte
    #:char-common-lvb-grid-horizontal
    #:char-common-lvb-grid-lvertical
    #:char-common-lvb-grid-rvertical
    #:char-common-lvb-reverse-video
    #:char-common-lvb-underscore
    #:char-info
    #:char-info-char
    #:char-info-attributes
    #:console-cursor-info
    #:make-console-cursor-info
    #:console-cursor-size
    #:console-cursor-visible
    #:coord
    #:coord-x
    #:coord-y
    #:coord-to-dword
    #:coord-from-dword
    #:console-font-info
    #:make-console-font-info
    #:console-font
    #:console-font-size
    #:console-font-info-ex
    #:make-console-font-info-ex
    #:console-ex-font
    #:console-ex-font-size
    #:console-ex-font-family
    #:console-ex-font-weight
    #:console-ex-face-name
    #:console-history
    #:make-console-history-info
    #:console-history-buffer-size
    #:console-history-number-of-history-buffers
    #:console-history-flags
    #:control-key-state
    #:control-key-capslock-on
    #:control-key-enhanced-key
    #:control-key-left-alt-pressed
    #:control-key-left-ctrl-pressed
    #:control-key-numlock-on
    #:control-key-right-alt-pressed
    #:control-key-right-ctrl-pressed
    #:control-key-scrollock-on
    #:control-key-shift-pressed
    #:console-read-control
    #:make-console-read-control
    #:console-rc-initial-chars
    #:console-rc-wakeup-mask
    #:control-rc-control-key-state
    #:small-rect
    #:small-rect-left
    #:small-rect-top
    #:small-rect-right
    #:small-rect-bottom
    #:console-screen-buffer-info
    #:make-console-screen-buffer-info
    #:console-sb-size
    #:console-sb-cursor-position
    #:console-sb-attributes
    #:console-sb-window
    #:console-sb-maximum-window-size
    #:console-screen-buffer-info-ex
    #:make-console-screen-buffer-info-ex
    #:console-sb-ex-size
    #:console-sb-ex-cursor-position
    #:console-sb-ex-attributes
    #:console-sb-ex-window
    #:console-sb-ex-maximum-window-size
    #:console-sb-ex-popup-attributes
    #:console-sb-ex-fill-screen-supported
    #:console-sb-ex-color-table
    #:console-selection-flags
    #:console-mouse-down
    #:console-mouse-selection
    #:console-no-selection
    #:console-selection-in-progress
    #:console-selection-not-empty
    #:console-selection-info
    #:make-console-selection-info
    #:console-selection-flags
    #:console-selection-anchor
    #:console-selection
    #:focus-event-record
    #:make-focus-event-record
    #:focus-event-set-focus
    #:key-event-record
    #:make-key-event-record
    #:key-event-key-down
    #:key-event-repeat-count
    #:key-event-virtual-key-code
    #:key-event-char
    #:key-event-control-key-state
    #:menu-event-record
    #:make-menu-event-record
    #:mouse-event-record
    #:make-mouse-event-record
    #:mouse-event-mouse-position
    #:mouse-event-button-state
    #:mouse-event-control-key-state
    #:mouse-event-flags
    #:window-buffer-size-record
    #:make-window-buffer-size-record
    #:window-buffer-event-size
    #:input-record
    #:make-input-record
    #:input-record-event-type
    #:input-record-event
    #:std-handle
    #:std-input-handle
    #:std-output-handle
    #:std-error-handle
    #:add-console-alias
    #:alloc-console
    #:attach-console
    #:create-console-screen-buffer
    #:fill-console-output-attribute
    #:fill-console-output-character
    #:flush-console-input-buffer
    #:free-console
    #:generate-console-ctrl-event
    #:get-console-alias
    #:get-console-aliases-length
    #:get-console-aliases
    #:get-console-alias-exes-length
    #:get-console-alias-exes
    #:console-input-code-page
    #:console-output-code-page
    #:console-cursor-info
    #:console-display-mode
    #:console-fullscreen
    #:console-fullscreen-hardware
    #:get-console-font-size
    #:console-mode
    #:enable-echo-input
    #:enable-insert-mode
    #:enable-line-io
    #:enable-mouse-input
    #:enable-processed-io
    #:enable-quick-edit-mode
    #:enable-window-input
    #:get-console-original-title
    #:get-console-process-list
    #:get-console-selection-info
    #:console-title
    #:get-console-window
    #:current-console-font
    #:current-console-font-ex
    #:get-largest-console-window-size
    #:get-number-of-console-input-events
    #:get-number-of-console-mouse-buttons
    #:peek-console-input
    #:read-console
    #:read-console-input
    #:read-console-output
    #:read-console-output-attribute
    #:read-console-output-character
    #:scroll-console-screen-buffer
    #:console-active-screen-buffer
    #:console-ctrl-handler
    #:console-cursor-position
    #:console-text-attribute
    #:console-screen-buffer-size
    #:set-console-window-info
    #:write-console
    #:write-console-input
    #:write-console-output
    #:write-console-output-attribute
    #:write-console-output-character
    ))