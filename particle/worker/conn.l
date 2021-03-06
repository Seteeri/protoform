# Requests are sent
# Cmds are recieved

##############################################
  
(de req-send-obj (Ipc Sock Obj Sz Off)

  (let (Msg (fmt-msg-send> Obj Off)
        Ptr (meta Obj 'ptr))

    ~(assert Sz)
    
    #(prinl-info "req-send-obj" Msg)
    
    (send-msg Ipc
              Sock
              Msg
              Ptr
              (wr-ptr> Obj Ptr))))


(de req-recv-obj (Ipc Sock Obj Sz Off)
  # Either pass in object or instance new one

  (let Msg (fmt-msg-recv> Obj Off)

    ~(assert Sz)
  
    #(prinl-info "req-recv-obj" Msg)
  
    (send-msg Ipc
              Sock
              Msg))

  (recv-obj Ipc
            Sock
            Obj
            Sz))


################################################################################

(de req-send (Ipc Obj)
  
  #(println Obj (get Obj 'val) (get Obj 'off-gl))
  ~(assert (get Obj 'off-gl))
  
  (req-send-obj Ipc
                (ipc~fd> *ipc "RENDER")
                Obj
                (meta Obj 'sz-pl)
                (get Obj 'off-gl)))
               

(de req-recv-vert (Ipc Sock Obj Cnt Off)
  (req-recv-obj Ipc
                Sock
                (if Obj @ (new '(+Vertex)))
                (meta '(+Vertex) 'sz-pl)
                Off))


(de req-recv-pv (Ipc Sock Obj Off)
  (req-recv-obj Ipc
                Sock
                (if Obj @ (new '(+Projview)))
                (meta '(+Projview) 'sz-pl)
                Off))


################################################################################
 
#{
(de req-recv-to-obj (Ipc Obj Cnt)
  (req-recv-obj Ipc
                (ipc~fd> *ipc "RENDER")
                Obj
                (meta Obj 'sz-pl)
                (get Obj 'off-gl)))

                
(de req-recv (Ipc Cls Cnt)
  (req-recv-obj Ipc
                (ipc~fd> *ipc "RENDER")
                (new Cls)
                (meta Cls 'sz-pl)))
}#
