(in-package #:protoform.model)

(defun memcpy-shm-to-cache (name
			    &optional
			      (offset 0)
			      (size-cpy nil))
  (with-slots (conn-swank
	       handles-shm)
      *model*
    (with-slots (ptr size)
	(gethash name handles-shm)
      ;; (fmt-model t "main-model" "(memcpy-shm-to-cache ~S ~S ~S)~%" name name size)
      (eval-sync
       conn-swank
       (format nil "(memcpy-shm-to-cache ~S ~S ~S ~S)" name name offset size-cpy)))))
      
(defun memcpy-shm-to-cache* (names)
  ;; Default to full copy
  (with-slots (conn-swank
	       handles-shm)
      *model*
    (eval-sync
     conn-swank
     (with-output-to-string (stream)
       (format stream "(progn ")
       (dolist (name names)
	 (with-slots (ptr size)
	     (gethash name (handles-shm *model*))
	   (format stream "(memcpy-shm-to-cache ~S ~S 0 nil) " name name)))
       (format stream ")")))))

(defun set-cache-dirty (name value)
  (with-slots (conn-swank)
      *model*
    (eval-sync
     conn-swank
     (format nil "(set-cache-flag-copy ~S ~S)" name value))))

(defun memcpy-shm-to-cache-flag* (caches)
  (with-slots (conn-swank
	       handles-shm)
      *model*    
    (eval-sync
     conn-swank
     (with-output-to-string (stream)
       (format stream "(progn ")
       (dolist (cache caches)
	 (destructuring-bind (name-cache
			      offset-cache
			      size-cache)
	     cache
	   (with-slots (ptr size)
	       (gethash name-cache handles-shm)
	     ;; Pass offsets
	     (format stream "(memcpy-shm-to-cache ~S ~S ~S ~S) " name-cache name-cache offset-cache size-cache)
	     (format stream "(set-cache-flag-copy ~S 3) " name-cache))))
       (format stream ")")))))
