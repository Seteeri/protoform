# Are these commands also?

(de adv-ptr (Cnt)

  (with *vert-ptr
    (let Pos (list (+ (get (: pos) 1) (*/ *adv-vert Cnt 1.0))
                   (get (: pos) 2)
                   0.0)
      (=: pos Pos))
      
  (update-model-matrix> *vert-ptr)
  (cmd-update-vert *ipc *vert-ptr)
  
  (prinl-info "adv-ptr" (pack (format (get Pos 1) *Scl) " " (format (get Pos 2) *Scl)))))


(de nl-ptr ()

  (with *vert-ptr
    (let Pos (list 0.0
                   (- (get (: pos) 2) (+ *adv-vert *adv-vert))
                   0.0)
      (=: pos Pos)))
      
  (update-model-matrix> *vert-ptr)
  (cmd-update-vert *ipc *vert-ptr))