(def '*data-node (list 143 7 180 62 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 119 42 178 62 0 0 0 0 0 0 0 0 0
                       0 0 0 0 0 0 0 111 18 3 60 0 0 0 0 152 242 44 61 86 98 183 61 0 0 0 0 0 0 128
                       63 182 181 53 63 138 137 9 63 0 0 0 0 0 0 128 63 182 181 53 63 138 137 9 63 0
                       0 0 0 0 0 128 63 182 181 53 63 138 137 9 63 0 0 0 0 0 0 128 63 182 181 53 63
                       138 137 9 63 0 0 0 0 0 0 128 63 117 154 58 63 40 255 57 63 0 0 0 0 0 0 0 0
                       117 154 58 63 176 1 140 62 0 0 0 0 0 0 0 0 20 203 138 62 176 1 140 62 0 0 0 0
                       0 0 0 0 20 203 138 62 40 255 57 63 0 0 0 0 0 0 0 0 0 196 5 0 96 0 0 0 96 0 0
                       0 1 0 0 0))


(def '*data-proj (list 171 170 42 61 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                       136 69 74 61 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                       32 64 128 187 0 0 0 0 0 0 0 128 0 0 0 128 64 128 128 191 0 0 128 63))


(def '*data-view (list 0 0 128 63 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                       128 63 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                       128 63 0 0 0 0 0 0 48 193 0 0 0 65 0 0 32 193 0 0 128 63))


(de test-projview ()
    #Write projview
    (let (I 0
            Ptr (get (get '*buffer-objects 'projview) 'gl~ptr))
      (for B *data-proj
           (struct (+ Ptr I) 'N (cons B 1))
           (inc 'I)))
    (let (I 64
            Ptr (get (get '*buffer-objects 'projview) 'gl~ptr))
      (for B *data-view
           (struct (+ Ptr I) 'N (cons B 1))
           (inc 'I))))

(de test-vert ()
    #Write test node
    (let (I 0
            Ptr (get (get '*buffer-objects 'nodes) 'gl~ptr))
      (for B *data-node
           (struct (+ Ptr I) 'N (cons B 1))
           (inc 'I))))


(de handle-memcpy (Sock Events Data)
  #(mc dst src sz)
  (let (Data (any Msg)
        Dst  (get Data 2)
        Src  (get Data 3)
        Sz   (get Data 4))
    (ipc~recv-bytes> *ipc Sock Events NIL Sz)
    #(println "recv-conn-ctrl" (struct (get *ipc 'ipc~buf-rd) '(B . 128)))
    (let (Ptr-Gl  (get (get '*buffer-objects 'projview) 'gl~ptr)
          Ptr-Buf (get *ipc 'ipc~buf-rd))
      (memcpy Ptr-Gl Ptr-Buf Sz))))