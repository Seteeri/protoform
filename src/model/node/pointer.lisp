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
    ;; Remember to dec on removal
    (sb-ext:atomic-incf (car *vertices-digraph*))
    node-ptr))

(defun init-node-pointer-graph-shm ()
  (let ((node-pointer (init-node-pointer)))
    (digraph:insert-vertex *digraph*
			   node-pointer)
    (copy-nodes-to-shm)
    node-pointer))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; These should have argument for pointer: default is pointer

(defun insert-node (node &optional (pos :before))
  ;; Linking Process:
  ;;
  ;; (ins here)
  ;;    |
  ;; [a]<-[*] (start)
  ;; [b]
  ;;
  ;; #1
  ;; [a] [*]
  ;; [b] 
  ;;
  ;; #2
  ;; [a]->[b] [*]
  ;;
  ;; #3
  ;; [a]->[b]<-[*]

  ;; Ordered this way in case there is no node-*
  
  ;; Really inserting node before pointer
  (let ((node-* (first (digraph:successors *digraph* *node-pointer*))))
    (when node-*
      ;; 1. Remove edge between node-*   and ptr
      ;; 2. Insert edge between node-*   and node-new
      (digraph:remove-edge *digraph* *node-pointer* node-*)
      (digraph:insert-edge *digraph* node-*         node)))
  
  ;; 3. Insert edge between node new and ptr
  (digraph:insert-edge *digraph* *node-pointer* node))

(defun link-node-pointer (node &optional (unlink-preds nil))
  ;; 1. Remove edge between node-*
  ;; 2. Insert edge between node new
  (let ((node-* (first (digraph:successors *digraph* *node-pointer*))))
    (when node-*
      (when unlink-preds
	(digraph:remove-edge *digraph*
			     *node-pointer*
			     node-*))
      (digraph:insert-edge *digraph*
			   *node-pointer*
			   node))))

(defun translate-pointer (seq-event
			  ptree
			  queue
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
			     seq-key
			     anim)))))

(defun translate-pointer-left-cb (seq-event
				  ptree
				  queue)
  (with-slots (model-matrix)
      *node-pointer*
    (translate-pointer seq-event
		       ptree
		       queue
		       (lambda (value-new) ; update fn
			 (setf (vx3 (translation model-matrix)) value-new)
			 (enqueue-node-pointer))
		       (vx3 (translation model-matrix)) ; start
		       (- (* 96 *scale-node*))          ; delta
		       'move-pointer-x)))

(defun translate-pointer-right-cb (seq-event
				   ptree
				   queue)
  (with-slots (model-matrix)
      *node-pointer*
    (translate-pointer seq-event
		       ptree
		       queue
		       (lambda (value-new)
			 (setf (vx3 (translation model-matrix)) value-new)
			 (enqueue-node-pointer))
		       (vx3 (translation model-matrix))
		       (* 96 *scale-node*)
		       'move-pointer-x)))

(defun translate-pointer-up-cb (seq-event
				ptree
				queue)
  (with-slots (model-matrix)
      *node-pointer*
    (translate-pointer seq-event
		       ptree
		       queue
		       (lambda (value-new)
			 (setf (vy3 (translation model-matrix)) value-new)
			 (enqueue-node-pointer))
		       (vy3 (translation model-matrix))
		       (* +linegap+ *scale-node*)
		       'move-pointer-y)))

(defun translate-pointer-down-cb (seq-event
				  ptree
				  queue)
  (with-slots (model-matrix)
      *node-pointer*
    (translate-pointer seq-event
		       ptree
		       queue
		       (lambda (value-new)
			 (setf (vy3 (translation model-matrix)) value-new)
			 (enqueue-node-pointer))
		       (vy3 (translation model-matrix))
		       (- (* +linegap+ *scale-node*))
		       'move-pointer-y)))
