(in-package :protoform.model)

;; /proc/sys/net/core/rmem_default for recv and /proc/sys/net/core/wmem_default
;; 212992
;; They contain three numbers, which are minimum, default and maximum memory size values (in byte), respectively.

(defun align-size (size &optional (boundary 4))
  (+ size (- boundary (mod size boundary))))

;; rename to graph or root?
(defclass model ()
  ((width :accessor width :initarg :width :initform nil)
   (height :accessor height :initarg :height :initform nil)
   (inst-max :accessor inst-max :initarg :inst-max :initform nil)

   ;; Integrate these into corresponding slot - data-model
   (sl-chrs :accessor sl-chrs :initarg :sl-chrs :initform nil)
   (lock-sl-chrs :accessor lock-sl-chrs :initarg :lock-sl-chrs :initform (bt:make-lock))
   (projview :accessor projview :initarg :projview :initform nil)
   ;; Rename mapping-base -> data-shm
   (mapping-base :accessor mapping-base :initarg :mapping-base :initform (make-hash-table :size 6 :test 'equal))
   
   (conn-model :accessor conn-model :initarg :conn-model :initform nil)
   ;; Make class - integrate with conn? (inc cohesion)
   (epoll-events :accessor epoll-events :initarg :epoll-events :initform nil)
   (epoll-fd :accessor epoll-fd :initarg :epoll-fd :initform nil)

   ;; Make class
   (queue-chrs :accessor queue-chrs :initarg :queue-chrs :initform (make-queue))
   (queue-pv :accessor queue-pv :initarg :queue-pv :initform (make-queue))
      
   ;; Make class - layout (inc cohesion)
   (metrics :accessor metrics :initarg :metrics :initform nil)
   (dpi-glyph :accessor dpi-glyph :initarg :dpi-glyph :initform nil)
   (scale-glyph :accessor scale-glyph :initarg :scale-glyph :initform nil)
   (cursor :accessor cursor :initarg :cursor :initform nil)))

(defun init-model (width
		   height
		   inst-max
		   path-server-model)

  (let* ((model (make-instance 'model
			       :width width
			       :height height
			       :projview (make-instance 'projview
							:width width
							:height height
							:projection-type 'orthographic)
			       :inst-max inst-max
			       :conn-model (init-conn-server path-server-model)
			       :metrics (init-metrics))))
    
    (setf (dpi-glyph model) (/ 1 90))
    (setf (scale-glyph model) (* (scale (gethash 32 (metrics model)))
				 (dpi-glyph model)))

    ;; TEXT DRAW PROCESS
    ;; 1. Pango will render text
    ;; 2. Apply msdf (do later)
    ;; 3. Write to texture buffer

    ;; SHM INIT PROCESS
    ;; 1. Model: init shm
    ;; 2. Model: init data
    ;; 3. Model: init memcpy on client connect
    ;; 4. View:  init OpenGL buffer objects for compute and raster; set binding points
    ;; 5. View:  init shm
    ;; 6. View:  render loop, bind/memcpy buffers
    
    ;; Init shms, request view to mmap
    ;; TODO:
    ;; Read cfg file (s-exp) to set parameters for mmaps
    ;; View also needs a cfg file since it corresponds for mmaps - or gen automatically?
    ;;
    ;; Note, element-array and draw-indirect buffers exist
    (format t "[main-model] Initializing mmaps...~%")
    (init-mapping-base inst-max
		       (mapping-base model)
		       (list (list "projview" "/protoform-projview.shm" (align-size (* (+ 16 16 16) 4 1)))
			     (list "instance" "/protoform-instance.shm" (align-size (* (/ 208 4) 4 inst-max)))
			     (list "texture" "/protoform-texture.shm" (align-size (* 96 96 255))))) ; from texture init
    
    ;; Init data for shms
    (with-slots (ptr size)
	(gethash "projview" (mapping-base model))
      (update-projection-matrix (projview model))
      (update-view-matrix (projview model))
      (set-projection-matrix ptr (projection-matrix (projview model)))
      (set-view-matrix ptr (view-matrix (projview model)))
      (let ((b (+ 16 16))
	    (data (init-vector-position 1)))
	(dotimes (i (length data))
	  (setf (mem-aref ptr :float (+ b i))
		(aref data i)))))
    
    ;; Epoll fds among server and clients
    ;; Clients must indicate if they are view or controller type
    (let ((epoll-fd (c-epoll-create 1)))
      (ctl-epoll epoll-fd
		 (sock (conn-model model))
		 #x0001
		 :add)
      (setf (epoll-fd model) epoll-fd))
    (setf (epoll-events model) (foreign-alloc '(:struct event) :count 3))
        
    model))


(defun main-model (width height
		   inst-max
		   path-server-model)
  
  (let* ((model (init-model width
			    height
			    inst-max
			    path-server-model)))

    ;; Create 3D objects now!

    ;; TODO
    ;; * Context -> Default FB
    ;; * Default FN -> Pipeline -> Buffers
    ;; * Render into node?
    ;;
    ;; * Text layout slowing us down so offload to Pango/Cairo
    ;;
    ;; * Build forward then forward+

    ;; Implement Pango/Cairo

    ;; The current buffer setup is for rendering nodes/planes
    ;; Users would need to create a new buffer object and structs for own format

    (let* ((cursor (vec3 0.0 0.0 0.0))
	   (inst-chr (init-chr cursor
			       (gethash 88 (metrics model))
			       (scale-glyph model)
			       (dpi-glyph model)
			       #\X))
	   (offset-ptr 0)
	   (metrics (metrics model)))
      
      (with-slots (ptr size)
	  (gethash "instance" (mapping-base model))
	 (with-slots (chr
		      model-matrix
		      rgba
		      flags)
	     inst-chr
	   
	   (loop
	      :for c :across (marr (matrix model-matrix))
	      :for c-i :upfrom 0
	      :do (setf (mem-aref ptr :float (+ offset-ptr c-i))
			c))
	   (incf offset-ptr 16)
	   
	   (loop
	      :for c :across rgba
	      :for c-i :upfrom 0
	      :do (setf (mem-aref ptr :float (+ offset-ptr c-i))
			c))
	   (incf offset-ptr 16)
	   
	   ;; (u v s t) * 4
	   (loop
	      :for c :across (uv (gethash (char-code chr) metrics))
	      :for c-i :upfrom 0
	      :do (setf (mem-aref ptr :float (+ offset-ptr c-i))
			c))
	   (incf offset-ptr 16)
	   
	   ;; Glyph, Flags, pad, pad
	   (setf (mem-aref ptr :int (+ offset-ptr 0)) (- (char-code chr) 32))
	   (setf (mem-aref ptr :int (+ offset-ptr 1)) flags)
	   (incf offset-ptr 4))))


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Mmap file read-only into structure
    ;; Layout chars
    (when nil
      (let* ((path-src (merge-pathnames #P"src/" (asdf:system-source-directory :protoform)))
	     (path-protoform (merge-pathnames (make-pathname :name "test" :type "txt")
					      path-src)))
	(multiple-value-bind (sl-chrs cursor)
	    (load-file inst-max
		       path-protoform
		       (metrics model)
		       (dpi-glyph model)
		       (scale-glyph model))
	  (setf (sl-chrs model) sl-chrs)
	  (setf (cursor model) cursor)))

      ;; Could use thread but this will be faster...
      (serialize-chrs (mapping-base model)
		      (sl-chrs model)
		      (metrics model)
		      (dpi-glyph model)
		      (scale-glyph model))
      
      (when t
	(bt:make-thread (lambda ()
			  (run-thread-chrs model)))
	(bt:make-thread (lambda ()
			  (run-thread-pv model)))))
    
    (loop (wait-epoll model))))

(defun load-file (inst-max
		  path-protoform
		  metrics
		  dpi-glyph
		  scale-glyph)
  
  (multiple-value-bind (ptr size) (mmap-file path-protoform)

    (when (> size inst-max)
      (warn "[main-model] Text truncated due to buffer size, > ~a ~a" size inst-max))

    (let* ((sl-chrs (skip-list:init-skip-list size t)))
      
      (loop
	 :with cursor = (vec3 0.0 0.0 0.0) ; spatial
	 :for i :from 0 :below size
	 :for ch = (code-char (mem-aref (inc-pointer ptr i) :char))
	 :do (progn
	       (skip-list:set-nth-data sl-chrs
				       (1+ i)
				       (layout-char metrics
						    cursor
						    ch
						    dpi-glyph
						    scale-glyph))))
      
      (format t "[load-file] sl-chars length: ~a~%" (skip-list:sl-length sl-chrs))
      
      ;; Could use xy for cursor
      (values sl-chrs
	      (vec2 1 0)))))

(defun handle-escape (msdf
		      keysym)
  
  (clean-up-model msdf)
  (glfw:set-window-should-close))

(defun clean-up-model (msdf)
  (loop 
     :for key :being :the :hash-keys :of (mapping-base msdf)
     :using (hash-value mmap)
     :do (cleanup-mmap mmap))

  (request-exit (conn-model msdf))
  
  (format t "[handle-escape] Model/Controller exiting!~%")

  ;; Only for DRM?
  (sb-ext:exit))

(defun wait-epoll (msdf)
  (with-slots (conn-model
	       epoll-fd
	       epoll-events)
      msdf
    ;; -1 = timeout = block/infinite
    ;; 0 = return if nothing

    ;; number of events should equal number of connections or max connections

    ;; store callback in data or get func from hash table
    
    (let ((fds-n (c-epoll-wait epoll-fd epoll-events 3 -1)))
      (when (> fds-n 0)
	(loop
	   :for i :from 0 :below fds-n
	   :for fd := (foreign-slot-value (foreign-slot-value (mem-aptr epoll-events '(:struct event) 0) '(:struct event) 'data)
					  '(:union data)
					  'fd)
	   :do (cond ((= fd (sock conn-model))
		      ;; Handle server
		      
		      (let* ((conn-client (accept-client conn-model msdf))
			     (sock-client (sock conn-client)))

			(format t "[wait-epoll] Client ~a connected~%" sock-client)

			;; Add to epoll
			(ctl-epoll epoll-fd
				   sock-client
				   (logior #x0001 #x008 #x010) ; EPOLLIN, EPOLLERR, EPOLLHUP
				   :add)
			
			;; Store in hash-table
			(setf (gethash sock-client (clients conn-model))
			      conn-client)
			    			
			;; TEMP
			(if (eq (id conn-client) :view)
			    (setf (view conn-model) conn-client)
			    (setf (controller conn-model) conn-client))

			;; Initialize data for VIEW client only
			(when (eq (id conn-client) :view)
			  (dolist (name (list "projview"
					      "instance"
					      "texture"))
			    (with-slots (ptr size)
				(gethash name (mapping-base msdf))
			      (request-memcpy conn-client name name size nil)))
			  ;; sync
			  (request-sync conn-client)))
		      
		      t)
		   

		     ;; Handle client
		     ;; Primarily watch for requests from controller
		     ;; View connection is used to send requests
		     ;; View has no reason to modify model - that is done through controller
		     (t
		      
		      ;; (format t "[wait-epoll] Client ~a sent data, ~a~%" fd (gethash fd (clients conn-model)))

		      (serve-client (gethash fd (clients conn-model))
				    msdf)
		      
		      t)))))))

;; REFACTOR SKIP-LIST: Iterate from passed node
;; Could cache loop node here to skip O log(N) operation
;; -> high probability nodes are sequential

(defun run-thread-chrs (msdf)
  ;; Needs client
  (with-slots (conn-model
	       mapping-base
	       sl-chrs
	       metrics
	       dpi-glyph
	       scale-glyph
	       cursor
	       queue-chrs
	       lock-sl-chrs)
      msdf
    (loop
       :for task := (pop-queue queue-chrs)
       :do (when (>= task 0)

	     (bt:with-lock-held (lock-sl-chrs)

	       (format t "[run-thread-chrs] Starting task @ ~a~%" task)
	       
	       (let* ((offset-ptr 0)
		      (counter-batch 0)
		      (size-batch 19) ; 208 bytes
		      (offset-batch 0)
		      (cursor (vec3 0.0 0.0 0.0)))

		 ;; lock skiplist?
		 
		 (skip-list:doskiplist
		  (sl-chr sl-chrs)

		  ;; Check queue for cancel
		  (when (not (queue-empty-p queue-chrs))
		    ;; (format t "[run-thread-chrs] Cancelling current task~%")
		    (return))
		  
		  ;; Otherwise process char
		  (multiple-value-bind (new-offset)
		      (update-shm-from-chr sl-chr
					   mapping-base
					   metrics
					   dpi-glyph
					   scale-glyph
					   cursor
					   offset-ptr)
		    (setf offset-ptr new-offset))

		  ;; Update batch
		  (incf counter-batch)
		  (when (>= counter-batch size-batch)
		    (request-memcpy (view conn-model)
				    "instance" "instance"
				    (* counter-batch 208)
				    nil
				    :offset-dest offset-batch
				    :offset-src  offset-batch)
		    (incf offset-batch (* counter-batch 208))
		    (setf counter-batch 0))		 
		  ;; skip list end
		  t)
		 
		 ;; Update incomplete batch
		 (when (> counter-batch 0)
		   (request-memcpy (view conn-model)
		 		  "instance" "instance"
		 		  (* counter-batch 208)
		 		  t
		 		  :offset-dest offset-batch
		 		  :offset-src  offset-batch)
		   (incf offset-batch (* counter-batch 208))
		   (setf counter-batch 0))
		 
		 (format t "[run-thread-chrs] Finished updating~%")

		 t))))))

(defun update-shm-from-chr (sl-chr
			    mapping-base
			    metrics
			    dpi-glyph
			    scale-glyph
			    cursor
			    offset-ptr)

  (let* ((metrics-space (gethash 32 metrics))
	 (uv-space (uv metrics-space)))

    (with-slots (ptr size)
	(gethash "instance" mapping-base)
    
      (with-slots (chr
		   model-matrix
		   rgba
		   flags)
	  sl-chr
	
	(cond ((char-equal chr #\Tab)
	       t)

	      ;; ascii
	      (t

	       ;; (format t "[update-chrs] ~a~%" chr)

	       (update-transform-chr cursor
				     (if (char-equal chr #\Newline)
					 metrics-space
					 (gethash (char-code chr) metrics))
				     scale-glyph
				     dpi-glyph
				     sl-chr)
	       
	       (when (and (char-equal chr #\Newline) t)
		 ;; After new chr, move down, reset x for next char
		 ;; Treat it like a space...
		 (setf (vx3 cursor) 0)
		 (decf (vy3 cursor) (* 9.375 2.0 scale-glyph)))
	       
	       (loop
		  :for c :across (marr4 (matrix model-matrix))
		  :for i :upfrom 0
		  :do (setf (mem-aref ptr :float (+ offset-ptr i))
			    c))
	       (incf offset-ptr 16)
	       
	       (loop
		  :for c :across rgba
		  :for i :upfrom 0
		  :do (setf (mem-aref ptr :float (+ offset-ptr i))
			    c))
	       (incf offset-ptr 16)
	       
	       ;; (u v s t) * 4
	       (loop
		  :for c :across (if (char-equal chr #\Newline)
				     uv-space
				     (uv (gethash (char-code chr) metrics)))
		  :for i :upfrom 0
		  :do (setf (mem-aref ptr :float (+ offset-ptr i))
			    c))
	       (incf offset-ptr 16)
	       
	       ;; Glyph, Flags, pad, pad
	       (setf (mem-aref ptr :int (+ offset-ptr 0)) (- (char-code chr) 32))
	       (setf (mem-aref ptr :int (+ offset-ptr 1)) flags)
	       (incf offset-ptr 4))))))

  offset-ptr)

(defun clear-queue (queue)
  (when (not (queue-empty-p queue-chrs))
    ;; lock required?
    (loop :until (queue-empty-p queue-chrs) :do (pop-queue queue-chrs))))

(defun run-thread-pv (msdf)
  (loop
     :for task := (pop-queue (queue-pv msdf))
     :do (format t "[run-thread-pv] Task: ~a~%" task)))
