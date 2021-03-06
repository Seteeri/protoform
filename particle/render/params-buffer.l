(class +Params-Buffer)

(dm T (Name
       Target
       Size
       Index-cs
       Index-vs
       Type-format)
    (=: name Name)
    (=: target Target)
    (=: size-b Size)
    (=: index-cs Index-cs)
    (=: index-vs Index-vs)
    (=: type-format Type-format))


(def '*params-buffer 
     (list (new '(+Params-Buffer)
                'atomic-counter
                gl~ATOMIC-COUNTER-BUFFER
                (* 4 6)  #6 ints/params
                4 -1 #-1 means same as cs
                NIL)
                
          (new '(+Params-Buffer)
                'draw-indirect
                gl~DRAW-INDIRECT-BUFFER
                (* 4 6)  #6 ints/params
                -1 -1
                NIL)

          (new '(+Params-Buffer)
                'element
                gl~ELEMENT-ARRAY-BUFFER
                (* 4 6)  #4 bytes/int * 6 ints or indices
                -1 -1
                NIL)

          (new '(+Params-Buffer)
                'texture-glyphs
                gl~TEXTURE-BUFFER 
                (* 128 1024 1024)
                -1 -1
                'rgba8)
          
          (new '(+Params-Buffer)
                'projview
                gl~UNIFORM-BUFFER
                (* (+ 16 16) 4)
                0 0  #cs-in (cache), vs-in (raster)
                NIL)

          (new '(+Params-Buffer)
                'vertices
                gl~UNIFORM-BUFFER
                (* 16 4)
                1 1
                NIL)

          (new '(+Params-Buffer)
                'nodes
                gl~SHADER-STORAGE-BUFFER
                (* *verts-max (meta '(+Vertex) 'sz-gl))
                3 3
                NIL)))
          # 134217728 = 128 MB
