(in-package :protoform.model)

;; From Solaris Red
;; 220  50  47
(defparameter *color-default-ptr* (list (coerce (/ 181 255) 'single-float)
					(coerce (/ 137 255) 'single-float)
					(coerce (/ 0   255) 'single-float)
					(coerce (/ 255 255) 'single-float)
					
					(coerce (/ 181 255) 'single-float)
					(coerce (/ 137 255) 'single-float)
					(coerce (/ 0   255) 'single-float)
					(coerce (/ 255 255) 'single-float)
					
					(coerce (/ 181 255) 'single-float)
					(coerce (/ 137 255) 'single-float)
					(coerce (/ 0   255) 'single-float)
					(coerce (/ 255 255) 'single-float)
					
					(coerce (/ 181 255) 'single-float)
					(coerce (/ 137 255) 'single-float)
					(coerce (/ 0   255) 'single-float)
					(coerce (/ 255 255) 'single-float)))

(defun init-node-pointer ()
  (let ((node-ptr (init-node-msdf (vec3 0 0 0)
				  *scale-node*
				  0
				  #\*
				  *color-default-ptr*)))
    (update-transform (model-matrix node-ptr))
    node-ptr))

(defun init-node-pointer-graph-shm ()
  (let ((node-pointer (init-node-pointer)))
    (insert-vertex node-pointer)
    (copy-nodes-to-shm)
    node-pointer))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; POSS: Refactor get-node-* to use *node-pointer* when no arg

(defun get-node-in-ptr ()
  (get-node-in *node-pointer*))

(defun get-node-out-ptr ()
  (get-node-out *node-pointer*))

(defun get-node-bi-ptr ()
  (values (get-node-in *node-pointer*)
	  (get-node-out *node-pointer*)))

 ;; Specific functions for pointer-context linking

;; Refactor these to generic nodes....

(defun link-node-pointer (node &optional (dir :out))
  ;; pos:
  ;; before = node -> *
  ;; after = * -> nodae
  (cond ((eq dir :in)  (insert-edge node *node-pointer*))
	((eq dir :out) (insert-edge *node-pointer* node))
	(t             (error "link-node-pointer: dir invalid"))))

(defun unlink-node-pointer (&optional (dir :out))
  (cond ((eq dir :in)
	 (when-let ((* (get-node-in-ptr)))
		   (remove-edge * *node-pointer*)
		   *))
	((eq dir :out)
	 (when-let ((* (get-node-out-ptr)))
		   (remove-edge *node-pointer* *)
		   *))
	((eq dir :bi)
	 (multiple-value-bind (node-* *-node)
	     (get-node-bi-ptr)
	   (when node-*
	     (remove-edge node-* *node-pointer*))
	   (when *-node
	     (remove-edge *node-pointer* *-node))
	   (values node-* *-node)))
	(t
	 (error "unlink-node-pointer: dir invalid"))))

(defun relink-node-pointer (node &optional
				   (dir-old :out)
				   (dir-new :out))
  ;; Return edges?
  (unlink-node-pointer dir-old)
  (link-node-pointer node dir-new))

;; translate block

(defun translate-pointer (seq-event
			  fn-new
			  start
			  delta
			  id)
  (fmt-model t "translate-pointer" "~a, ~a -> ~a~%"
	     id
	     start
	     (+ start
		delta))
  
  (let ((anim (make-instance 'animation
			     :id id
			     :fn-easing #'easing:in-exp ;cubic
			     :fn-new fn-new
			     :value-start start
			     :value-delta delta)))
    ;; in animation.lisp
    (enqueue-anim anim
		  id
		  (lambda ()
		    (funcall #'run-anim
			     seq-event
			     anim)))))

(defun edge-pointer ()
  ;; Move before or after
  t)
