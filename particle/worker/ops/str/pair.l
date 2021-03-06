(de mak-str-xa-x (Str Pt-B Pt-C) (con-a-pair-x Str Pt-B Pt-C))
(de mak-str-xb-x (Str Pt-B Pt-C) (con-b-pair-x Str Pt-B Pt-C))

(de mak-str-xa-y (Str Pt-B Pt-C) (con-a-pair-y Str Pt-B Pt-C))
(de mak-str-xb-y (Str Pt-B Pt-C) (con-b-pair-y Str Pt-B Pt-C))


(de mak-str-ya-x (Str Pt-B Pt-C) (con-a-pair-x Str Pt-B Pt-C))
(de mak-str-yb-x (Str Pt-B Pt-C) (con-b-pair-x Str Pt-B Pt-C))

(de mak-str-ya-y (Str Pt-B Pt-C) (con-a-pair-y Str Pt-B Pt-C))
(de mak-str-yb-y (Str Pt-B Pt-C) (con-b-pair-y Str Pt-B Pt-C))


(de con-b-pair-x (Str Pt-B Pt-C)
  
  #{
  
    Connect new list cdr to cur atom
    Update pointer before updating cur pair
    Then connect new list to cur pair
    Draw main
    Mov cur to ptr
    Draw ptr
    
    * If X-Pair on newline (start of line), 
    mov newline to new Pair
    
    In:

                   *
        [X]  [X]  [X]  .
         .    .    .
          
    Out:

                        *
        [X]  [X]  [X]  [X]  .
         .    .   ..    .
      
    Repeat:

                            *
        [X]  [X]  [X]  [X]  [X]  .
         .    .   ..   ...   .


    In:

              *
        [Y]  [X1] .
              .
            
        .
        
    Out:

                    *
        [Y]  [X2]  [X1] .
              .     .
            
        .
      
  }#
  
  (println 'con-b-pair-x)
  
  (let (C (get Pt-C 'any)
        Ls (list Str)
        Pt-Ls (gen-point Ls 'x NIL T))
    
    (con> Pt-B Ls)
    (con> Pt-Ls C Pt-C T)
    
    (when (get Pt-C 'line)
      (mov-line Pt-C Pt-Ls)
      (lns> *ptr))
    (set-ln-n> *ptr Pt-Ls)
    
    (lay-*start)
    
    # dont use pt since it will set prev col to sel
    # update any
    (put *ptr 'any Ls)
    
    (top-ref> *ptr)
    (draw> *ptr)))


(de con-b-pair-y (Str Pt-B Pt-C)
  #{
  
    Case 1: (1 2) -> (1 3 2)
        
        [X1]
         .
      
         *
        [Y]  .
            
         .
            
    -->
              
        [X1]
         .
      
         *
        [X2]
         .
        
        [Y]  .
            
         .
    
    Put X2 after X1
    
  }#
  
  (println 'con-b-pair-y)
  
  (let (B (get Pt-B 'any)
        C (get Pt-C 'any)
        Ls (list Str)
        Pt-Ls (gen-point Ls 'x NIL))
    
    # B -> Ls -> C
    #
    # B = poss
    # Ls = yes
    # C = yes
        
    (con> Pt-B Ls Pt-Ls NIL)
    (con> Pt-Ls C Pt-C 'del)
    
    # Con lines
    
    (when (get Pt-B 'line)
      (put @ 'n Pt-Ls))
    
    (with (get Pt-Ls 'line)
      (=: p (cadr (get *ptr 'lns)))
      (=: n Pt-C))

    (put Pt-C 'line 'p Pt-Ls)      
      
    # Expanded symbol
    # Handle this better...call method
    (when (get Pt-B 'exp)
      (put Pt-B 'line 'n NIL)
      (put Pt-Ls 'line 'p NIL))
        
    # Pop cur line (Pt-C), push new list
    (lns> *ptr) (lns> *ptr Pt-Ls) 
    
    (lay-*start)    
    
    # Need new fn
    (uncol> *ptr Pt-C T)
    (pt> *ptr B 'b T T)
    
    (top-ref> *ptr)
    (draw> *ptr)))


(de con-a-pair-y (Str Pt-B Pt-C)
  #{
  
    Case 1: ((1)) -> ((2 1))

              *
        [Y]  [Y] .
              .
            
        .
            
    -->
      
              *
        [Y]  [X]
              .
        
             [Y] .
              .
            
        .  
        
  }#
  
  (let (B (get Pt-B 'any)
        C (get Pt-C 'any)
        Ls (list Str)
        Pt-Ls (gen-point Ls 'x NIL))
        
    (set> Pt-B Ls Pt-Ls)
    (con> Pt-Ls C Pt-C 'del)
        
    (with (get Pt-Ls 'line)
      (=: p NIL)
      (=: n Pt-C))
    
    (put Pt-C 'line 'p Pt-Ls)
                
    # Pop cur line (Pt-C), push new list
    (lns> *ptr) (lns> *ptr Pt-Ls)        
        
    (pt> *ptr Ls 'a)
        
    (lay-*start)    
    
    (top-ref> *ptr)
    (draw> *ptr)))


(de con-a-pair-x (Str Pt-B Pt-C)
  #{
          
    Case 2: ((1)) -> ((2 1))

              *
        [Y]  [X1]  .
              .
            
        .
            
    -->
      
                    *
        [Y]  [X2]  [X1]  .
              .     .
            
        .  
        
  }#
  
  (println 'con-a-pair-x)
  
  (let (B (get Pt-B 'any)
        C (get Pt-C 'any)
        Ls (list Str)
        Pt-Ls (gen-point Ls 'x NIL T))
    
    (set> Pt-B Ls Pt-Ls)
    (con> Pt-Ls C Pt-C 'del)

    # Mov line from C -> Ls
    (when (get Pt-C 'line)    
      (mov-line Pt-C Pt-Ls)
      (lns> *ptr))
    (set-ln-n> *ptr Pt-Ls)
        
    # same ref
    (with *ptr
      (=: any Ls)
      (=: reg 'b))
        
    (lay-*start)
    
    (top-ref> *ptr)
    (draw> *ptr)))
    
