(in-package :protoform.controller)

;; mirror of model variables
(defparameter *controller* nil)
(defparameter *channel-input* nil)
(defparameter *path-devices* "/dev/input/event*")

(defclass controller () 
  ((context :accessor context :initarg :context :initform nil)
   (xkb :accessor xkb :initarg :xkb :initform nil)
   (key-states :accessor key-states :initarg :key-states :initform (make-hash-table :size 256))
   (key-callbacks :accessor key-callbacks :initarg :key-callbacks :initform (make-hash-table :size 256))
   (ep-events :accessor ep-events :initarg :ep-events :initform nil)
   (ep-fd :accessor ep-fd :initarg :ep-fd :initform nil)))   

(defun init-controller (channel-input &rest devices)
  (let ((controller (make-instance 'controller
				   :context (libinput:path-create-context (libinput:make-libinput-interface)
									  (null-pointer))
				   :xkb (init-xkb))))
    (with-slots (context
		 ep-fd
		 ep-events)
	controller

      (init-devices devices context)
      
      (setf ep-fd     (init-epoll context)
            ep-events (foreign-alloc '(:struct event))))

    (setf *controller* controller)
    (setf *channel-input* channel-input)
    
    controller))

(defun init-devices (devices context)
  (if devices
      (mapcar (lambda (path)
		(libinput:path-add-device context path))
	      devices)
      (let ((device-paths (directory *path-devices*)))
	(loop
	   :for device-path :in device-paths
	   :do (let ((device (libinput:path-add-device context
						       (namestring device-path))))
		 (when (not (null-pointer-p device))
		   (if (not (or (libinput:device-has-capability device
								libinput:device-cap-keyboard)
				(libinput:device-has-capability device
								libinput:device-cap-pointer)))
		       (libinput:path-remove-device device))))))))

(defun init-epoll (context)
  (let ((ep-fd (c-epoll-create 1)))
    (ctl-epoll ep-fd
	       (libinput:get-fd context)
	       #x0001 ; TODO: defconstant
	       :add)
    ep-fd))

(defun run-controller ()
  (loop
     (dispatch-events-input)             ; serial
     ;; only do below if keyboard events
     (dispatch-all-seq-event)            ; parallel
     (update-states-keyboard-continuous) ; parallel
     t))

(defun dispatch-events-input ()
  ;; Poss pull events and submit task instead of processing in parallel
  ;; However, would need to allocate separate ep-events for each callback
  (with-slots (context
	       ep-fd
	       ep-events)
      *controller*
    ;; -1 = timeout = block/infinite
    ;; 0 = return if nothing
    (when (> (c-epoll-wait ep-fd ep-events 1 -1) 0)
      (loop
      	 :for event := (progn
			 (libinput:dispatch context)
			 (libinput:get-event context))
      	 :until (null-pointer-p event)
      	 :do
      	   (dispatch-event-handler event)
      	   (libinput:event-destroy event)
	 :finally (libinput:dispatch context)))))

(defun dispatch-event-handler (event)

  ;; libinput:none
  ;; libinput:device-added
  ;; libinput:device-removed
  ;; libinput:keyboard-key
  ;; libinput:pointer-motion
  ;; libinput:pointer-motion-absolute
  ;; libinput:pointer-button
  ;; libinput:pointer-axis
  ;; libinput:touch-down
  ;; libinput:touch-motion
  ;; libinput:touch-up
  ;; libinput:touch-cancel
  ;; libinput:touch-frame
  ;; libinput:gesture-swipe-begin
  ;; libinput:gesture-swipe-update
  ;; libinput:gesture-swipe-end
  ;; libinput:gesture-pinch-begin
  ;; libinput:gesture-pinch-update
  ;; libinput:gesture-pinch-end
  ;; libinput:tablet-tool-axis
  ;; libinput:tablet-tool-proximity
  ;; libinput:tablet-tool-tip
  ;; libinput:tablet-tool-button
  ;; libinput:tablet-pad-button
  ;; libinput:tablet-pad-ring
  ;; libinput:tablet-pad-strip
  ;; libinput:switch-toggle

  (let ((type (libinput:event-get-type event)))
    ;; (format t "type: ~a~%" type)
    (cond
      ((= type libinput:keyboard-key)
       (handle-event-keyboard event))
      ((= type libinput:pointer-motion)
       ;; (format t "type: ~a~%" type)
       t)
      
      ((= type libinput:touch-down)
       (handle-event-touch event))

      ((= type libinput:touch-motion)
       (handle-event-touch event))

      ((= type libinput:touch-up)
       (handle-event-touch-2 event))

      ((= type libinput:touch-cancel)
       (handle-event-touch-2 event))
      
      ((= type libinput:touch-frame)
       (handle-event-touch-2 event))
      
      ((= type libinput:pointer-button)
       t)

      ((= type libinput:tablet-tool-axis)
       (handle-event-tablet-tool-axis event))

      ((= type libinput:tablet-tool-proximity)
       (handle-event-tablet-tool-proximity event))

      ((= type libinput:tablet-tool-tip)
       (handle-event-tablet-tool-tip event))
      
      (t
       t))

    type))
