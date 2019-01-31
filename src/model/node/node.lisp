(in-package :protoform.model)

(defconstant +size-struct-instance+ 208)
(defconstant +scale-msdf+ 5.8239365)
(defconstant +spaces-tab+ 1)

(defparameter *dpi-glyph* (/ 1 90))
(defparameter *scale-node* 0.008)
(defparameter +linegap+ (* (* 9.375 2)    ;; use advance....
			   +scale-msdf+))  ;; multiplied by scale-node later (per node)

(defparameter *uv-default-node* (list 1.0 1.0  0.0 0.0
			  	      1.0 0.0  0.0 0.0
			  	      0.0 0.0  0.0 0.0
			  	      0.0 1.0  0.0 0.0))

(defparameter *color-default-node* (list  (coerce (/ 131 255) 'single-float)
					  (coerce (/ 148 255) 'single-float)
					  (coerce (/ 155 255) 'single-float)
					  (coerce (/ 255 255) 'single-float)

					  (coerce (/ 131 255) 'single-float)
					  (coerce (/ 148 255) 'single-float)
					  (coerce (/ 155 255) 'single-float)
					  (coerce (/ 255 255) 'single-float)

					  (coerce (/ 131 255) 'single-float)
					  (coerce (/ 148 255) 'single-float)
					  (coerce (/ 155 255) 'single-float)
					  (coerce (/ 255 255) 'single-float)

					  (coerce (/ 131 255) 'single-float)
					  (coerce (/ 148 255) 'single-float)
					  (coerce (/ 155 255) 'single-float)
					  (coerce (/ 255 255) 'single-float)))

(defparameter *data-zero-node* (make-array +size-struct-instance+
					   :adjustable nil
					   :fill-pointer nil
					   :element-type '(unsigned-byte 8)
					   :initial-element (coerce 0 '(unsigned-byte 8))))
;; :data (make-array size
;; 		  :element-type '(unsigned-byte 8)
;; 		  :initial-element (coerce 0 '(unsigned-byte 8)))

(defclass node ()
  ((data :accessor data :initarg :data :initform nil)
   
   (offset-texel-texture :accessor offset-texel-texture :initarg :offset-texel-texture :initform 0)
   (dims-texture :accessor dims-texture :initarg :dims-texture :initform (vec2 0 0))
   (uv :accessor uv :initform (make-array 16
					  :adjustable nil
					  :fill-pointer nil
					  :element-type 'single-float
					  :initial-contents *uv-default-node*))
   
   (index :accessor index :initarg :index :initform nil)
   (origin :accessor origin :initarg :origin :initform (vec3 0 0 0))
   (model-matrix :accessor model-matrix :initarg :model-matrix :initform (make-instance 'model-matrix))
   (rgba :accessor rgba :initarg :rgba :initform (make-array (* 4 4) ; or use vec4
							     :adjustable nil
							     :fill-pointer nil
							     :element-type 'single-float
							     :initial-contents *color-default-node*))
   (flags :accessor flags :initarg :flags :initform 1)))

(defun node-rect (node)
  "make a bounding box function."
  (with-slots (model-matrix)
      node

    (let ((pos (translation model-matrix))
	  (scale (scale model-matrix)))
      
      ;; use scale to create bounds

      ;; lx,ly = left-bottom
      ;; hx,hy = top right
      
      (rectangles:make-rectangle
       :lows (list (vx3 pos)
		   (vy3 pos))
       :highs (list (+ (vx3 pos) (vx3 scale))
		    (+ (vy3 pos) (vy3 scale)))))))

(defun randomize-color-node (vert)
  ;; random color
  (setf (aref (rgba vert) 0)  (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 1)  (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 2)  (coerce (random 1.0) 'single-float)
	;; (aref (rgba vert) 3)  (coerce (/ 255 255)  'single-float)
	
	(aref (rgba vert) 4)  (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 5)  (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 6)  (coerce (random 1.0) 'single-float)
	;; (aref (rgba vert) 7)  (coerce (/ 255 255)  'single-float)
	
	(aref (rgba vert) 8)  (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 9)  (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 10) (coerce (random 1.0) 'single-float)
	;; (aref (rgba vert) 11) (coerce (/ 255 255)  'single-float)
	
	(aref (rgba vert) 12) (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 13) (coerce (random 1.0) 'single-float)
	(aref (rgba vert) 14) (coerce (random 1.0) 'single-float)
	;; (aref (rgba vert) 15) (coerce (/ 255 255)  'single-float)
	)
  (enqueue-node vert))

(defun init-node-msdf (cursor
		       scale-glyph
		       ix
		       data
		       &optional
			 (color nil))

  (let ((node (make-instance 'node
			     :data data
			     :index ix
			     :model-matrix (make-instance 'model-matrix
							  :scale (vec3 scale-glyph
								       scale-glyph
								       scale-glyph)
							  :translation (vcopy3 cursor))))
	(metrics-glyph (gethash (char-code data) *metrics*)))

    ;; Remember to dec on removal
    (sb-ext:atomic-incf (car *vertices-digraph*))
    
    ;; Set color
    (when color
      (let ((rgba (rgba node)))
	(dotimes (i 16)
	  (setf (aref rgba i) (nth i color)))))

    ;; ascii - 1
    (setf (offset-texel-texture node) (* (- (char-code data) 1) 96 96)
          (dims-texture node)         (make-array 2
						  :adjustable nil
						  :initial-contents '(96 96)))
    
    (with-slots (bounds-origin
		 dims-glyph
		 uv)
	metrics-glyph

      ;; All textures have been cropped through UV
      ;; so glyphs touch edges of node - allows proper spacing
      ;; so nodes don't physically overlap
      ;; This means the y position needs to be adjusted
      ;; by the rel-to-baseline/translate bottom bounds
      ;;
      ;; The x position is adjusted also...
      ;;
      ;; Fonts are monospaced so the advance is the same for every font
      ;; Advance is from one origin to the next origin
      ;; The left bottom corner of the first char/node is considered the baseline
      ;; - Question is whether the glyph should touch that or adjust from there
      ;;   - Then first char x pos would need not be shifted
      (let ((translation-mm (translation (model-matrix node))))
	(setf (vx3 translation-mm) (+ (vx3 cursor)
				      (* (aref bounds-origin 0) scale-glyph))
	      (vy3 translation-mm) (+ (vy3 cursor)
				      (* (aref bounds-origin 1) scale-glyph))
	      (vz3 translation-mm) (vz3 cursor)))

      ;; Aspect ratio of node must match aspect ratio of UV
      ;; otherwise texture will appear distorted
      (let ((scale-mm (scale (model-matrix node))))
      	(setf (vx3 scale-mm) (* (vx2 dims-glyph) scale-glyph)
      	      (vy3 scale-mm) (* (vy2 dims-glyph) scale-glyph)))

      (setf (uv node) uv))
    
    ;; Update transform
    (update-transform (model-matrix node))
    
    node))

(defun serialize-node (node)
  ;; (let ((data (make-array +size-struct-instance+
  ;; 			  :fill-pointer 0
  ;;                      :adjustable nil
  ;; 			  :element-type '(unsigned-byte 8))))
  (with-slots (data
	       model-matrix
	       rgba
	       offset-texel-texture
	       dims-texture
	       uv
	       flags)
      node
    (let ((marr (marr (matrix model-matrix))))
      (pack:pack "<48f4i"
		 (aref marr 0)  (aref marr 1)  (aref marr 2)  (aref marr 3)
		 (aref marr 4)  (aref marr 5)  (aref marr 6)  (aref marr 7)
		 (aref marr 8)  (aref marr 9)  (aref marr 10) (aref marr 11)
		 (aref marr 12) (aref marr 13) (aref marr 14) (aref marr 15)
		 (aref rgba 0)  (aref rgba 1)  (aref rgba 2)  (aref rgba 3)
		 (aref rgba 4)  (aref rgba 5)  (aref rgba 6)  (aref rgba 7)
		 (aref rgba 8)  (aref rgba 9)  (aref rgba 10) (aref rgba 11)
		 (aref rgba 12) (aref rgba 13) (aref rgba 14) (aref rgba 15)
		 (aref uv 0)    (aref uv 1)    (aref uv 2)    (aref uv 3)
		 (aref uv 4)    (aref uv 5)    (aref uv 6)    (aref uv 7)
		 (aref uv 8)    (aref uv 9)    (aref uv 10)   (aref uv 11)
		 (aref uv 12)   (aref uv 13)   (aref uv 14)   (aref uv 15)
		 offset-texel-texture
		 (aref dims-texture 0)
		 (aref dims-texture 1)
		 flags))))

(defun insert-vertex (vert)
  (digraph:insert-vertex *digraph* vert)
  (sb-ext:atomic-incf (car *vertices-digraph*)))

(defun remove-vertex (vert)
  (digraph:remove-vertex *digraph* vert)
  (sb-ext:atomic-decf (car *vertices-digraph*)))

(defun insert-edge (vert-a vert-b)
  (digraph:insert-edge *digraph* vert-a vert-b)
  (sb-ext:atomic-incf (car *edges-digraph*)))

(defun remove-edge (vert-a vert-b)
  (digraph:remove-edge *digraph* vert-a vert-b)
  (sb-ext:atomic-decf (car *edges-digraph*)))

;; TODO:
;; - Refactor 3x below to macros
;; - Add arg to get first or all
;;   - Ignore pointer

(defun get-nodes-in (* &optional (ptr-ignore t))
  ;; Filter pointer?
  (digraph:predecessors *digraph* *))

(defun get-nodes-out (*)
  ;; POSS: Add ignore-ptr
  (digraph:successors *digraph* *))

(defun get-node-in (* &optional (ptr-ignore t))
  (if ptr-ignore
      (dolist (node-i (digraph:predecessors *digraph* *))
      	(unless (eq node-i *node-pointer*)
      	  (return-from get-node-in node-i)))
      (first (digraph:predecessors *digraph* *))))

(defun get-node-out (*)
  ;; POSS: Add ignore-ptr
  (first (digraph:successors *digraph* *)))

(defun get-node-bi (*)
  (values (get-node-in *)
	  (get-node-out *)))

(defun get-node-dir (* dir)
  (cond ((eq dir :in)  (get-node-in *))
	((eq dir :out) (get-node-out *))
	((eq dir :bi)  (get-node-bi *))))

(defun link-node (node-src node-dest dir)
  ;; TEMP: add assertion to prevent cycles, aka node link to itself
  ;; (when (not (eq node-src node-dest))
  ;;   (draw-graph)
  ;;   (assert (not (eq node-src node-dest))))
  (assert (not (eq node-src node-dest)))
  (cond ((eq dir :in)
	 (insert-edge node-src node-dest))
	((eq dir :out)
	 (insert-edge node-dest node-src))))

(defun unlink-node (node-src node-dest dir)
  (cond ((eq dir :in)
	 (remove-edge node-src node-dest))
	((eq dir :out)
	 (remove-edge node-dest node-src))))

(defun unlink-node-first (* &optional (dir :out)) ; does first
  (cond ((eq dir :in)
	 (when-let ((node-* (get-node-in *)))
		   (remove-edge node-* *)
		   node-*))
	((eq dir :out)
	 (when-let ((*-node (get-node-out *)))
		   (remove-edge * *-node)
		   *-node))
	((eq dir :bi)
	 (multiple-value-bind (node-* *-node)
	     (get-node-bi *)
	   (when node-*
	     (remove-edge node-* *))
	   (when *-node
	     (remove-edge * *-node))
	   (values node-* *-node)))))

(defun print-node-dirs (&key
			  (node-ptr *node-pointer*)
			  (dir-ptr :out))
  ;; Print node
  (when-let ((node-ref (get-node-ptr-out)))	    
	    (let ((nodes-ref-in (loop :for n :in (get-nodes-in node-ref) :collect (data n)))
		  (nodes-ref-out (loop :for n :in (get-nodes-out node-ref) :collect (data n))))
	      (format t "ptr: ~a~%" *node-pointer*)
	      (format t "ptr-ref (ptr out): ~a~%" node-ref)
	      (format t "in: ~a~%" nodes-ref-in)
	      (format t "out: ~a~%" nodes-ref-out))))

(defun add-node (data &optional (move-pointer t))
  (let* ((baseline (get-origin-from-node-pos *node-pointer*))
	 (node (init-node-msdf baseline
			       *scale-node*
			       (digraph:count-vertices *digraph*)
			       data)))

    (insert-vertex node)
    (spatial-trees:insert node *r-tree*)
    
    ;; hello-world
    ;;
    ;;         world
    ;; hello-<
    ;;         user
    
    (when-let* ((node-ptr-out (get-node-ptr-out))
		(node-type (get-node-type node-ptr-out)))

	       ;; Push new node above for now
	       (when (or (eq node-type :intra)
			 (eq node-type :start))
		 (let* ((bounds-origin (bounds-origin (gethash (char-code (data node)) *metrics*))))
		   (translate-node-to-node node
					   node
					   :offset (vec3 0.0
    							 (* +linegap+ *scale-node*)
    							 0.0)))))
    ;; attach node to ptr
    (insert-node node *node-pointer* :out)
    ;; advance pointer
    (when move-pointer
      (advance-node-of-node *node-pointer*
    			    node
    			    1.0))
        
    node))

;; rename to join
(defun insert-node (node-src
		    node-dest
		    dir-src)
  
  ;; Procedure
  ;;
  ;; Scenario #1 - Insert b out of * (into a):
  ;; a <------ * | GIVEN B
  ;; a <- b <- * | GOAL
  ;;
  ;; - Plugin 

  ;; Scenario #2 - Insert b into *:
  ;; a <- * <------ c | GIVEN B
  ;; a <- * <- b <- c | GOAL
  
  ;; nodes in opposite direction remain attached

  ;; does not insert-vertex into graph
  
  (loop
     :for node :in (cond ((eq dir-src :in)
			  (get-nodes-in node-dest))
			 ((eq dir-src :out)
			  (get-nodes-out node-dest)))
     :do (progn
	   (unlink-node node     node-dest dir-src)
	   ;; (format t "~S ~S: ~S~%" (data node-dest) dir-src (data node))
	   ;; (format t "~S - ~S : ~S~%" (data node-src) (data node) dir-src)
	   (link-node   node-src node      dir-src)))
  
  ;; link src to dest
  (link-node node-src
	     node-dest
	     dir-src))

(defun pop-node (&key
		   (node-ptr *node-pointer*)
		   (dir-ptr :out)
		   (update-transform t))

  ;; TODO
  ;; - add option for updating position
  
  ;; Cases:
  ;;   
  ;; - intra node:  y in, y out
  ;;   A -> B -> C
  ;;        *
  ;;   A ->   -> C
  ;;        *
  ;;   - move C next to A
  ;;   - point to C
  ;;
  ;;
  ;; - end node:    y in, n out
  ;;   A -> B -> C
  ;;             *
  ;;   A -> B -> 
  ;;        *
  ;;   - point to B
  ;;
  ;;
  ;; - start node:  n in, y out
  ;;   A -> B -> C
  ;;   *
  ;;     -> B -> C
  ;;        *
  ;;   - point to B
  ;;
  ;;
  ;; - single node: n in, n out
  ;;     B 
  ;;     *
  ;;   - do nothing

  (when-let ((node-ref (get-node-ptr-out)))
	    ;; Only unlink left side of pointer
	    (unlink-node-ptr :out)
	    
	    (let ((node-ref-in (get-node-in node-ref))
		  (node-ref-out (get-node-out node-ref)))

	      (cond ((and node-ref-in  ; delete-node-intra
			  node-ref-out)
		     ;; Insert C out of A
		     (insert-node node-ref-out node-ref-in :out)
		     ;; Link pointer to next node
		     (link-node-ptr node-ref-out)
		     (when update-transform
		       ;; Move C next to A
  		       (advance-node-of-node node-ref-out
  					     node-ref-in
  					     1.0)	     
		       ;; or use advance with self
  		       (translate-node-to-node *node-pointer*
  		       			       node-ref)
		       t))
		    
		    ;; delete-node-end
		    ((and node-ref-in
			  (not node-ref-out))
		     (link-node-ptr node-ref-in)
		     (when update-transform
		       ;; or use advance with self
  		       (translate-node-to-node *node-pointer*
  		       			       node-ref)
		       t))

		    ;; delete-node-start
		    ((and (not node-ref-in)
			  node-ref-out)
		     (link-node-ptr node-ref-out)
		     (when update-transform
		       ;; or use advance with self
  		       (translate-node-to-node *node-pointer*
  		       			       node-ref)
		       t))

		    ;; delete-node-iso
		    ((and (not node-ref-in)
			  (not node-ref-out))
		     (when update-transform
		       ;; or use advance with self		     
  		       (translate-node-to-node *node-pointer*
  		       			       node-ref))
		     t))
	      
	      ;; Return deleted node, and surrounding nodes (for shm update)
	      (values node-ref
		      node-ref-in
		      node-ref-out))))

(defun delete-node (&key
		      (node-ptr *node-pointer*)
		      (dir-ptr :out))

  (multiple-value-bind (node-ref
			node-ref-in
			node-ref-out)
      (pop-node :node-ptr node-ptr
		:dir-ptr dir-ptr)
    (when node-ref
      ;; Remove from graph (removes edges?)
      (remove-vertex node-ref)
      (spatial-trees:delete node-ref *r-tree*))
    (values node-ref
	    node-ref-in
	    node-ref-out)))

;; Secondary/Aux operators
;; Need to implement hyperweb first to identify nodes

(defun get-origin-from-node-pos (node)
  ;; Get origin from node position
  ;; l b r t
  (v+ (translation (model-matrix node))
      (let ((bounds-origin (bounds-origin (gethash (char-code (data node)) *metrics*))))
	(vec3 (- (* (aref bounds-origin 0) *scale-node*))
	      (- (* (aref bounds-origin 1) *scale-node*))
	      0.0))))

(defun advance-node-of-node (node-a
			     node-b
			     n-adv
			     &key
			       (offset (vec3 0 0 0)))
  (let* ((origin-b (get-origin-from-node-pos node-b))
	 (bounds-a (bounds-origin (gethash (char-code (data node-a)) *metrics*)))
	 (new-pos (v+ origin-b
		      offset
		      (vec3 (+ (* 9.375 +scale-msdf+ *scale-node* n-adv)
			       (* (aref bounds-a 0) *scale-node*))
			    (* (aref bounds-a 1) *scale-node*)
			    0.0))))
    (setf (translation (model-matrix node-a)) new-pos)
    (update-transform (model-matrix node-a))
    new-pos))

(defun translate-node-to-node (node-a
			       node-b
			       &key
				 (offset (vec3 0 0 0)))
  ;; Move node-a to node-b position; don't change links
  ;; Adjust for baseline
  (let* ((origin-b (get-origin-from-node-pos node-b))
	 (bounds-a (bounds-origin (gethash (char-code (data node-a)) *metrics*)))
	 (new-pos (v+ origin-b
		      offset
		      (vec3 (* (aref bounds-a 0) *scale-node*)
			    (* (aref bounds-a 1) *scale-node*)
			    0.0))))
    (setf (translation (model-matrix node-a)) new-pos)
    (update-transform (model-matrix node-a))
    new-pos))

(defun build-string-from-nodes ()
  ;; Pass starting node else use node-pointer
  ;; To eval, build string from predecessors until newline

  ;; (fmt-model t "build-string-from-nodes" "Pointer: ~a~%" *node-pointer*)
  
  (let ((chrs nil))
    (loop
       ;; currently assuming linear
       :for pred := (digraph:successors *digraph* *node-pointer*)
       :then (digraph:predecessors *digraph* pred)
       :while pred
       :do (loop
	      ;; Leave on first non-ptr node
	      :for node :in pred
	      :do (unless (eq node *node-pointer*)
		    (when (char-equal (data node) #\Newline)
		      (return))
		    (push (data node) chrs)
		    (setf pred node)
		    (return))))
    
    (with-output-to-string (stream)
      (dolist (c chrs)
	(write-char c stream)))))

(defun remove-all-nodes ()
  ;; Exclude pointer
  (digraph:mapc-vertices (lambda (v)
			   (unless (eq v *node-pointer*)
			     (enqueue-node-zero (index v))
			     (remove-vertex v)))
			 *digraph*)
  (digraph:mapc-edges (lambda (e)
			(remove-edge e))
		      *digraph*))

(defun nth-node (node-end nth)
  ;; This assumes a non-branching graph
  t)

(defun copy-node-to-node (node-src)
  (let* ((baseline (get-origin-from-node-pos node-src))
	 (node (init-node-msdf baseline
			       *scale-node* ; get from node-src
			       (digraph:count-vertices *digraph*)
			       (data node-src))))
    (insert-vertex node)
    node))

;; Find end, specify successor or predecessor direction
(defun find-node-line-start (node-end dir)
  (let ((node-start node-end)
	(fn (cond ((eq dir :in)
		   #'digraph:predecessors)
		  ((eq dir :out)
		   #'digraph:successors))))
    
    ;; Create fn - loop until specified character or pass lambda as predicate
    ;; Start with newline char instead of pointer or it will terminate immediately
    (loop :for pred := (funcall fn *digraph* node-end)
       :then (funcall fn *digraph* pred)
       :while pred
       :do (loop :for node :in pred
	      :do (unless (equal node *node-pointer*) ; skip pointer
		    ;; (format t "node: ~S = ~S~%" node (data node))
		    (when (char-equal (data node) #\Newline)
		      (return))
		    ;; Else set node to get preds and goto next iteration
		    (setf pred node
			  node-start node)
		    (return))))
    
    node-start))

(defun replace-node (node-src
		     node-dest
		     dir-src)
  
  ;; Procedure
  ;;
  ;; Insert d:
  ;;
  ;; a <- b <- * <- a | GIVEN
  ;;
  ;; 1. Unlink src
  ;; 1. Get all the ins of dest
  ;;    2. Unlink old, link new
  ;; 3. Get all the outs of dest
  ;;    4. Unlink old, link new

  ;; unlink old
  
  (let ((nodes-in (get-nodes-in node-dest))
	(nodes-out (get-nodes-out node-dest)))

    ;; Unlink dest
    (loop
       :for node :in nodes-in
       :do (remove-edge node node-dest))
    (loop
       :for node :in nodes-out
       :do (remove-edge node-dest node))

    ;; Link src
    (loop
       :for node :in nodes-in
       :do (insert-edge node node-src))
    (loop
       :for node :in nodes-out
       :do (insert-edge node-src node)))

  ;; Could easily do swap function
  t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Need do-node macro
(defmacro do-node ((var node-default dir-1 dir-2) &body body)
  `(let ((fn-1 (cond ((eq ,dir-1 :in)
		      #'digraph:predecessors)
		     ((eq ,dir-1 :out)
		      #'digraph:successors)
		     (t
		      t)))
	 (fn-2 (cond ((eq ,dir-2 :in)
		      #'digraph:predecessors)
		     ((eq ,dir-2 :out)
		      #'digraph:successors)
		     (t
		      t))))
     ;; Could detect first char to see which direction text is in...
     ;; - Might introduce bugs -> print warning?
     
     ;; Create fn - loop until specified character or pass lambda as predicate
     ;; Start with newline char instead of pointer or it will terminate immediately
     (loop
	:for pred := (funcall fn-1 *digraph* ,node-default)
	:then (funcall fn-2 *digraph* pred)
	:while pred
	:do (loop
	       :for node-pred :in pred
	       :do (unless (equal node-pred *node-pointer*) ; skip pointer
		     (let ((,var node-pred))
		       ,@body)
		     (setf pred node-pred))))))

(defun get-node-type (node-ref)
  (let ((node-ref-in (get-node-in node-ref))
	(node-ref-out (get-node-out node-ref)))
    (cond ((and node-ref-in
		node-ref-out)
	   :intra)
	  ((and node-ref-in
		(not node-ref-out))
	   :end)
	  ((and (not node-ref-in)
		node-ref-out)
	   :start)
	  ((and (not node-ref-in)
		(not node-ref-out))
	   :iso))))

(defun update-transform-line (node-start offset)
  ;; If assumed, glyphs are already aligned,
  ;; can use offset in line to update nodes simultaneously
  (let ((pos-start (translate (model-matrix node-start)))
	(node-prev nil))
    (do-node (node node-start :out :out)
      (setf (translation (model-matrix node))
	    (v+ (translation (model-matrix node))))
      (update-transform (model-matrix node))
      (enqueue-node node))))
