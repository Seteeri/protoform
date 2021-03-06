(de cmd-move-cam (Move)

   (with *projview

      (=: pos (list (+ (car (: pos)) (car Move))
                    (+ (cadr (: pos)) (cadr Move))
                    1.0))

      (let ((X Y Z) (: pos))
        (prinl-info 'cmd-move-cam (glue " " (list (format X *Scl) (format Y *Scl))))))

    (upd-mat-view> *projview)

    # Either send relevant data or send entire data
    # -> Minimize render processing time

    # Pass list of socks so need only serialize once

    (req-send *ipc *projview))


(de cmd-move-cam-px (Ks) (cmd-move-cam (list (meta '(+Vertex) 'adv-vert-2)     0.0)))
(de cmd-move-cam-nx (Ks) (cmd-move-cam (list (- (meta '(+Vertex) 'adv-vert-2)) 0.0)))
(de cmd-move-cam-py (Ks) (cmd-move-cam (list 0.0 (meta '(+Vertex) 'adv-vert-2))))
(de cmd-move-cam-ny (Ks) (cmd-move-cam (list 0.0 (- (meta '(+Vertex) 'adv-vert-2)))))


(de cmd-zoom-cam (Delta)

  (with *projview

    (inc (:: scale-ortho) Delta)
    
    (prinl-info 'cmd-zoom-cam (format (: scale-ortho) *Scl)))

  (upd-mat-proj> *projview)
  
  (req-send *ipc *projview))

# arbitrary...
(de cmd-zoom-cam-in  (Ks) (cmd-zoom-cam -1.0))
(de cmd-zoom-cam-out (Ks) (cmd-zoom-cam 1.0))
