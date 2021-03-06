#{
    Global variables start with an asterisk "*"
    Global constants may be written all-uppercase
    Functions and other global symbols start with a lower case letter
    Locally bound symbols start with an upper case letter
    Local functions start with an underscore "_"
    Classes start with a plus-sign "+", where the first letter
        is in lower case for abstract classes
        and in upper case for normal classes
    Methods end with a right arrow ">"
    Class variables may be indicated by an upper case letter
}#


(load (pack (pwd) "/particle/misc.l"))
(mapc 'ld-cwd
      (list "/particle/c/epoll.l"
            "/particle/c/li.l"
            "/particle/c/socket.l"
            "/particle/misc.l"
            "/particle/ipc/ipc.l"
            "/particle/prot/conn.l"
            "/particle/prot/send.l"
            "/particle/prot/recv.l"
            "/particle/prot/obj.l"))

(def 'NAME-PID "INPUT")

#Globals
(def '*input)
(def '*ipc)


(de init-input ()

  (setq *ipc (new '(ipc~+IPC)
                  *uds-in T serv-cli acpt-cli)
        *input (new '(li~+Li)))
  (ipc~add-conn> *ipc (get *input 'li~fd-context) "LI" serv-fd-li))


(de run-input (Timeout)

  (prinl-info "run-input" "Starting epoll...")
  (loop (ipc~poll> *ipc Timeout)))


(de serv-cli (Sock)

  (let (Msg (recv-msg *ipc Sock)
        Data (car (str Msg)))

    # recv-msg will return data or NIL
    # This means sending NIL will disconnect the client, like EOF
    
    (if Msg
        (when (= Data "bye")
          (send-msg-conns *ipc "(bye)")
          (ipc~disc-sock Sock)
          (end)
          (println "Input says bye!")
          (bye))
        (disc-cli *ipc Sock))))


(de serv-fd-li ()
  (with *input
    (li~dispatch (: li~context))
    (until (=0 (setq Ev (li~get-event (: li~context))))
       (send-event Ev)
       (li~event-destroy Ev)
       (li~dispatch (: li~context)))))


(de send-event (Ev)

  (let (Type (li~event-get-type Ev)
        Name (li~get-event-type-name Type))

    (let Msg (pack "("
                   (glue " " (make (link Name)
                                   (link (build-ev-lst Ev Type))))
                   ")")

      # Workers will send messages to input when they are ready      
      (send-msg-clients *ipc Msg))))


(de build-ev-lst (Ev Type)

  (cond ((= Type li~KEYBOARD-KEY)
          (glue " " (list (format (li~kb-get-time Ev))
                          (format (li~kb-get-time-usec Ev))
                          (format (li~kb-get-key Ev))
                          (format (li~kb-get-key-state Ev))
                          (format (li~kb-get-seat-key-count Ev)))))

        ((= Type li~POINTER-MOTION)
          (glue " " (list (format (li~ptr-get-time Ev))
                          (format (li~ptr-get-time-usec Ev))
                          (format (li~ptr-get-dx Ev) *Scl)
                          (format (li~ptr-get-dy Ev) *Scl)
                          (format (li~ptr-get-dx-unaccelerated Ev) *Scl)
                          (format (li~ptr-get-dy-unaccelerated Ev) *Scl))))

        ((= Type li~POINTER-MOTION-ABSOLUTE)
          (glue " " (list (format (li~ptr-get-time Ev))
                          (format (li~ptr-get-time-usec Ev))
                          (format (li~ptr-get-absolute-x Ev) *Scl)
                          (format (li~ptr-get-absolute-y Ev) *Scl)
                          (format (li~ptr-get-absolute-x-transformed Ev *width) *Scl)
                          (format (li~ptr-get-absolute-y-transformed Ev *height) *Scl))))

        ((= Type li~POINTER-BUTTON)
          (glue " " (list (format (li~ptr-get-time Ev))
                          (format (li~ptr-get-time-usec Ev))
                          (format (li~ptr-get-button Ev))
                          (format (li~ptr-get-button-state Ev))
                          (format (li~ptr-get-seat-button-count Ev)))))

        ((= Type li~POINTER-AXIS)
          (glue " " (list (format (li~ptr-get-time Ev))
                          (format (li~ptr-get-time-usec Ev))
                          (format (li~ptr-has-axis Ev Axis))
                          (li~get-pointer-axis-source-name (li~ptr-get-axis-source Ev))
                          (when (= (li~ptr-has-axis Ev Axis) 1)
                            (format (li~ptr-get-axis-value Ev li~POINTER-AXIS-SCROLL-HORIZONTAL) *Scl)
                            (format (li~ptr-get-axis-value Ev li~POINTER-AXIS-SCROLL-VERTICAL)   *Scl)
                            (format (li~ptr-get-axis-value-discrete Ev li~POINTER-AXIS-SCROLL-HORIZONTAL) *Scl)
                            (format (li~ptr-get-axis-value-discrete Ev li~POINTER-AXIS-SCROLL-VERTICAL)   *Scl)))))

        ((or (= Type li~TOUCH-UP)
              (= Type li~TOUCH-CANCEL)
              (= Type li~TOUCH-FRAME))
          (glue " " (list (format (li~tch-get-time Ev))
                          (format (li~tch-get-time-usec Ev)))))

        ((or (= Type li~TOUCH-DOWN)
              (= Type li~TOUCH-MOTION))
          (glue " " (list (format (li~tch-get-time Ev))
                          (format (li~tch-get-time-usec Ev))
                          (format (li~tch-get-x Ev) *Scl)
                          (format (li~tch-get-y Ev) *Scl)
                          (format (li~tch-get-x-transformed Ev *width) *Scl)
                          (format (li~tch-get-y-transformed Ev *height) *Scl))))))

(de end ()
  (ipc~end> *ipc)
  (li~end> *input))


(de main ()
    (bind-args)
    #(push '*Bye '(end-input))
    (init-input)
    (run-input -1)
    (bye))
