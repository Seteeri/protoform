(in-package :protoform.model)

;;;;;;;;;;;;;
;; relational

(defun print-node-dirs (&key
			  (node-ptr *node-ptr-main*)
			  (dir-ptr :out))
  ;; Print node
  (when-let ((node-ref (get-node-ptr-out)))	    
	    (let ((nodes-ref-in (loop :for n :in (get-nodes-in node-ref) :collect (char-glyph n)))
		  (nodes-ref-out (loop :for n :in (get-nodes-out node-ref) :collect (char-glyph n))))
	      (format t "ptr: ~a~%" *node-ptr-main*)
	      (format t "ptr-ref (ptr out): ~a~%" node-ref)
	      (format t "in: ~a~%" nodes-ref-in)
	      (format t "out: ~a~%" nodes-ref-out))))

;; rename to join
(defun insert-node (node-src
		    node-dest
		    dir-src
		    &optional
		      (graph *digraph-main*)
		      (edges *edges-main*))
  
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

  ;; only manages linkage
  
  (loop
     :for node :in (cond ((eq dir-src :in)
			  (get-nodes-in node-dest graph))
			 ((eq dir-src :out)
			  (get-nodes-out node-dest graph)))
     :do (progn
	   (unlink-node node
			node-dest
			dir-src
			graph
			edges)
	   (link-node node-src
		      node
		      dir-src
		      graph
		      edges)))
  
  ;; link src to dest
  (link-node node-src
	     node-dest
	     dir-src
	     graph
	     edges))

(defun pop-node (&key
		   (node-ptr *node-ptr-main*)
		   (dir-ptr :out))
  
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
	    (unlink-node-ptr :out) ; unlink ref only

	    (multiple-value-bind (type-node-ref
				  node-ref-in
				  node-ref-out)
		(get-node-type node-ref)

	      (cond ((eq type-node-ref :intra)
		     ;; Insert C out of A
		     (insert-node node-ref-out node-ref-in :out)
		     ;; Link pointer to next node
		     (link-node-ptr node-ref-out))
		    
		    ((eq type-node-ref :end)
		     (link-node-ptr node-ref-in))

		    ((eq type-node-ref :start)
		     (link-node-ptr node-ref-out))

		    ((eq type-node-ref :iso)
		     t))
	      
	      ;; Return deleted node, and surrounding nodes (for shm update)
	      (values node-ref
		      type-node-ref
		      node-ref-in
		      node-ref-out))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Rename add-node-to-ptr
(defun add-node (char-glyph
		 &optional
		   (baseline (get-origin-from-node-pos *node-ptr-main*)))
  (let ((node (pop *stack-i-nodes*)))
    
    (update-translation-node node baseline)
    (update-glyph-node node char-glyph)
    (update-transform-node node)
    
    (insert-vertex node)
    (spatial-trees:insert node *r-tree*)
    
    node))

(defun delete-node (&key
		      (node-ptr *node-ptr-main*)
		      (dir-ptr :out))

  (multiple-value-bind (node-ref
			type-node-ref
			node-ref-in
			node-ref-out)
      (pop-node :node-ptr node-ptr
		:dir-ptr dir-ptr)
    (when node-ref
      (translate-node-to-node *node-ptr-main*
  		       	      node-ref)
      (when (eq type-node-ref :intra)
	;; Move C next to A
  	(advance-node-of-node node-ref-out
  			      node-ref-in
  			      1.0))
      ;; Reset existing or push new
      (push (init-node-msdf (vec3 0 0 0)
  			    *scale-node*
  			    (index node-ref)
  			    nil
  			    nil)
	    *stack-i-nodes*)
      
      (remove-vertex node-ref)
      (spatial-trees:delete node-ref *r-tree*))
    (values node-ref
	    node-ref-in
	    node-ref-out)))

(defun copy-node-to-node (node-src)
  (let* ((baseline (get-origin-from-node-pos node-src))
	 (node (init-node-msdf baseline
			       *scale-node* ; get from node-src
			       (digraph:count-vertices *digraph-main*)
			       (char-glyph node-src))))
    (insert-vertex node)
    (spatial-trees:insert node *r-tree*)
    
    node))

(defun remove-all-nodes ()
  ;; Exclude pointer
  (digraph:mapc-vertices (lambda (v)
			   (unless (eq v *node-ptr-main*)
			     (enqueue-node-zero (index v))
			     (remove-vertex v)))
			 *digraph-main*)
  (digraph:mapc-edges (lambda (e)
			(remove-edge e))
		      *digraph-main*))

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
