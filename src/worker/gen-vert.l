# bg:fg/text = base03:base0

(def '*sol-base-03 (list (*/ 1.0 0.0   255.0) (*/ 1.0 43.0  255.0) (*/ 1.0 54.0  255.0)))
(def '*sol-base-02 (list (*/ 1.0 0.0   255.0) (*/ 1.0 54.0  255.0) (*/ 1.0 66.0  255.0)))
(def '*sol-base-01 (list (*/ 1.0 88.0  255.0) (*/ 1.0 110.0 255.0) (*/ 1.0 117.0 255.0)))
(def '*sol-base-00 (list (*/ 1.0 101.0 255.0) (*/ 1.0 123.0 255.0) (*/ 1.0 131.0 255.0)))

(def '*sol-base-0  (list (*/ 1.0 131.0 255.0) (*/ 1.0 148.0 255.0) (*/ 1.0 150.0 255.0)))
(def '*sol-base-1  (list (*/ 1.0 147.0 255.0) (*/ 1.0 161.0 255.0) (*/ 1.0 161.0 255.0)))
(def '*sol-base-2  (list (*/ 1.0 238.0 255.0) (*/ 1.0 232.0 255.0) (*/ 1.0 213.0 255.0)))
(def '*sol-base-3  (list (*/ 1.0 253.0 255.0) (*/ 1.0 246.0 255.0) (*/ 1.0 227.0 255.0)))

(def '*sol-violet  (list (*/ 1.0 108.0 255.0) (*/ 1.0 113.0  255.0) (*/ 1.0 196.0 255.0)))
(def '*sol-blue    (list (*/ 1.0 38.0  255.0) (*/ 1.0 139.0  255.0) (*/ 1.0 210.0 255.0)))
(def '*sol-cyan    (list (*/ 1.0 42.0  255.0) (*/ 1.0 161.0  255.0) (*/ 1.0 152.0 255.0)))
(def '*sol-green   (list (*/ 1.0 133.0 255.0) (*/ 1.0 153.0  255.0) (*/ 1.0 0.0   255.0)))
(def '*sol-yellow  (list (*/ 1.0 181.0 255.0) (*/ 1.0 137.0  255.0) (*/ 1.0 0.0   255.0)))

(def '*sol-orange  (list (*/ 1.0 203.0 255.0) (*/ 1.0 75.0 255.0) (*/ 1.0 22.0  255.0)))
(def '*sol-red     (list (*/ 1.0 220.0 255.0) (*/ 1.0 50.0 255.0) (*/ 1.0 47.0  255.0)))
(def '*sol-magenta (list (*/ 1.0 211.0 255.0) (*/ 1.0 54.0 255.0) (*/ 1.0 130.0 255.0)))


(de get-color-type (Any)
  #{
                        Cell
                          |
              +-----------+-----------+
              |           |           |
           Number       Symbol       Pair
                          |
                          |
     +--------+-----------+-----------+
     |        |           |           |
    NIL   Internal    Transient    External  

    Yellow = NIL (T?)
    Orange = Builtins
    Red = Pair
    Magenta = Num
    
    Violet = Int/Sym
    Blue = Str/Sym/Trans
    Cyan = Ext/Sym
    Green = Box/Sym/Trans

    Base = List
    
    White/Black = Ptrs
  }#

  # Adjust brightness for time...or alpha?

  (cond ((or (== Any NIL)
             (== Any T))  *sol-yellow)
        ((lst? Any)       *sol-base-0)
        ((num? Any)       *sol-magenta)
        ((box? Any)       *sol-green)
        ((str? Any)       *sol-blue)
        ((ext? Any)       *sol-cyan)
        ((sym? Any)       *sol-violet)))


(def '*char-dot (char 183))

(de gen-vert-dot (Col)
  (gen-vert-glyph *char-dot 
              (if Col @ *sol-base-0)))


(de gen-vert-glyph (Char Col Val)
  (let (Vert (pop '*verts)
        (R G B) Col)
    (inc '*cnt-v)
    (with Vert
      (=: ch (char Char)) # used for metrics look up 
      (=: val Val)
      (=: rgba (list R G B 1.0
                     R G B 1.0
                     R G B 1.0
                     R G B 1.0)))
    Vert))


(de gen-vert-repr (Repr Col)
  (let Verts ()
    (for Ch Repr
      (case Ch
        ("^J" (push 'Verts (gen-vert-glyph "\^" Col)
                           (gen-vert-glyph "J"  Col Ch)))
        ("^M" (push 'Verts (gen-vert-glyph "\^" Col)
                           (gen-vert-glyph "M"  Col Ch)))
        ("^I" (push 'Verts (gen-vert-glyph "\^" Col)
                           (gen-vert-glyph "I"  Col Ch)))
        (T    (push 'Verts (gen-vert-glyph Ch Col Ch)))))
        
    (flip Verts)))

  
(de gen-vert-str (Str Col)
  (let Verts (gen-vert-repr (chop Str) Col)
    (list Verts
          (*/ *adv-vert (num-to-fl (- (length Verts) 1)) 1.0))))

  
(de gen-vert-num (Num Col)
  (let Verts (gen-vert-repr (chop (format Num)) Col)
    (list Verts
          (*/ *adv-vert (num-to-fl (- (length Verts) 1)) 1.0))))


(de gen-vert-sym (Sym Col)
  (let Verts (gen-vert-repr (chop (sym Sym)) Col)
    (list Verts
          (*/ *adv-vert (num-to-fl (- (length Verts) 1)) 1.0))))
          

(de gen-vert-atom (Atom Col)

  (unless Col (setq Col (get-color-type Atom)))

  (cond ((num? Atom)             (gen-vert-num Atom Col))
        ((and (str? Atom) 
              (not (box? Atom))) (gen-vert-str Atom Col))
        (T           (gen-vert-sym Atom Col))))


(de gen-vert-pair (Col Self)

  # (char 187) (char 166)
  # (gen-vert-chars "[" *sol-base-0 T)
  
  (if Self
      (list (list (gen-vert-dot Col) (gen-vert-dot Col))
            *adv-vert-2)
      (list (list (gen-vert-dot Col))
            *adv-vert)))