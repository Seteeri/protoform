(in-package #:protoform.model)

(defparameter *path-socket-view* "/tmp/protoform-view.socket")
(defparameter *time-last* 0)

(defun handle-view-sync (time-view)

  ;; Input will trigger animations - need lock around structure
  ;;
  ;; Skipping/dropping frames will result in jerky/choppy animation

  ;; Each frame:
  ;; - Submit animations as tasks - list generated offline
  ;; - Wait for completion
  ;; - Update shm
  
  (when nil
    (let ((time (osicat:get-monotonic-time)))
      (format t "Model: ~8$ ms~%" (* (- time *time-last*) 1000))
      (setf *time-last* time)))
  
  ;; Need locks on conn and shm
  (submit-task *chan-anim*
	       #'animate-camera-x)
  
  (dotimes (i 1) (receive-result *chan-anim*))

  ;; Send signal back
  
  t)

(defun init-conn-rpc-view ()
  (setf *sock-view* (init-sock-client *path-socket-view* :block))

  ;; Combine all of below into single call
  
  ;; Init buffers  
  (send-message *sock-view*
		*buffer-sock-ptr*
		(with-output-to-string (stream)
		  (format stream "(init-view-buffers (")
		  (loop
		     :for (name params) :on *params-shm* :by #'cddr
		     :do (format stream "~S " params))
		  (format stream "))")))

  ;; See get-sym-shm-from-string
  (loop
     :for (name params) :on *params-shm* :by #'cddr
     :for name2 := (string-downcase (symbol-name name))
     :do (memcpy-shm-to-cache name2
			      (symbol-value (find-symbol (str:concat "shm-" name2) :protoform.model))))
  
  ;; Enable draw flag for view loop
  (send-message *sock-view*
		*buffer-sock-ptr*
		(format nil "(set-draw t)")))

(defun serve-client ()
  (loop
     (let ((message (recv-message *sock-view*
				  *buffer-sock-ptr*)))
       (when message
	 ;; (fmt-model t "serve-client" "Message: ~S~%" message)
	 ;; (print (eval message))
	 ;; (force-output)

	 (if (listp (first message))
	     (dolist (n message)
	       (apply (symbol-function (find-symbol (string (first n)) :protoform.model))
		      (cdr n)))
	     (apply (symbol-function (find-symbol (string (first message)) :protoform.model))
		    (cdr message)))))))

;; TODO: Use macro

(defun memcpy-shm-to-cache (name
			    shm
			    &optional
			      (offset 0)
			      (size-cpy nil))
  (with-slots (ptr size)
      shm
    ;; (fmt-model t "main-model" "(memcpy-shm-to-cache ~S ~S ~S)~%" name name size)
    (send-message *sock-view*
    		  *buffer-sock-ptr*
		  (format nil "(memcpy-shm-to-cache ~S ~S ~S ~S)" name name offset size-cpy))))

;; (defun memcpy-shm-to-cache (name
;; 			    &optional
;; 			      (offset 0)
;; 			      (size-cpy nil))
;;   (with-slots (ptr size)
;;       (gethash name *handles-shm*)
;;     ;; (fmt-model t "main-model" "(memcpy-shm-to-cache ~S ~S ~S)~%" name name size)
;;     (send-message *sock-view*
;;     		  *buffer-sock-ptr*
;; 		  (format nil "(memcpy-shm-to-cache ~S ~S ~S ~S)" name name offset size-cpy))))

(defun memcpy-shm-to-cache* (names)
  ;; Default to full copy
  (send-message *sock-view*
    		*buffer-sock-ptr*
		(with-output-to-string (stream)
		  (format stream "(")
		  (dolist (name names)
		    (with-slots (ptr size)
			(gethash name *handles-shm*)
		      (format stream "(memcpy-shm-to-cache ~S ~S 0 nil) " name name)))
		  (format stream ")"))))

(defun set-cache-dirty (name value)
  (send-message *sock-view*
    		*buffer-sock-ptr*
		(format nil "(set-cache-flag-copy ~S ~S)" name value)))

(defun memcpy-shm-to-cache-flag* (caches)
  (send-message *sock-view*
    		*buffer-sock-ptr*
		(with-output-to-string (stream)
		  (format stream "(")
		  (dolist (cache caches)
		    (destructuring-bind (name-cache
					 offset-cache
					 size-cache)
			cache
		      (with-slots (ptr size)
			  ;; (gethash name-cache *handles-shm*)
			  (get-sym-shm-from-string name-cache)
			;; Pass offsets
			(format stream "(memcpy-shm-to-cache ~S ~S ~S ~S) " name-cache name-cache offset-cache size-cache)
			(format stream "(set-cache-flag-copy ~S 3) " name-cache))))
		  (format stream ")"))))

;; Memoize
(defun get-sym-shm-from-string (string)
  (symbol-value (find-symbol (str:concat "shm-" string) :protoform.model)))
