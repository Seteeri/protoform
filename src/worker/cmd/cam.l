(de cmd-move-cam (Move)

   (with *projview

      (=: pos (list (+ (get (: pos) 1) (get Move 1))
                    (+ (get (: pos) 2) (get Move 2))
                    10.0)))

    (update-mat-view> *projview)

    # Either send relevant data or send entire data
    # -> Minimize render processing time

    # Pass list of socks so need only serialize once

    (cmd-update-pv *ipc))


(de cmd-move-cam-px (Keysym) (cmd-move-cam '(2.0   0.0)))
(de cmd-move-cam-nx (Keysym) (cmd-move-cam '(-2.0  0.0)))
(de cmd-move-cam-py (Keysym) (cmd-move-cam '(0.0    2.0)))
(de cmd-move-cam-ny (Keysym) (cmd-move-cam '(0.0   -2.0)))


(de cmd-zoom-cam (Delta)

  (with *projview

    (inc (:: scale-ortho) Delta))

  (update-mat-proj> *projview)

  (cmd-update-pv *ipc))


(de cmd-zoom-cam-in  (Keysym) (cmd-zoom-cam -2.0))
(de cmd-zoom-cam-out (Keysym) (cmd-zoom-cam  2.0))