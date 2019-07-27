#{
/*
 * Copyright © 2008 Kristian Høgsberg
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
}#

(symbols 'wl 'pico)

#{
/** \class wl_object
 *
 * \brief A protocol object.
 *
 * A `wl_object` is an opaque struct identifying the protocol object
 * underlying a `wl_proxy` or `wl_resource`.
 *
 * \note Functions accessing a `wl_object` are not normally used by client code.
 * Clients should normally use the higher level interface generated by the
 * scanner to interact with compositor objects.
 *
 */
}#
#struct wl_object;


(class +Message)
(dm T (Name Signature Types)

  # Malloc strings
  (=: name (native "@" "malloc" 'N (+ (length Name) 1)))
  (struct (: name) 'N (cons Name 1))
  
  (=: signature (native "@" "malloc" 'N (+ (length Signature) 1)))
  (struct (: signature) 'N (cons Signature 1))

  # types is double pointer
  
  (=: ptr (native "@" "malloc" 'N (+ 8 8 8)))
  (struct (: ptr) 'N (cons (: name) 8)
                     (cons (: signature) 8)
                     (cons (: types) 8)))

(dm get-ptr>     ()      (: ptr))


(class +Interface)
(dm T (Name Version Method-Count Methods Event-Count Events)

  # Malloc strings
  (=: name (native "@" "malloc" 'N (+ (length Name) 1)))
  (struct (: name) 'N (cons Name 1))
  
  (=: ptr (native "@" "malloc" 'N (+ 8 4 4 8 4 8)))
  (struct (: ptr) 'N (cons (: name) 8)
                     (cons Version 4)
                     (cons Method-Count 4)
                     (cons Methods 8)
                     (cons Event-Count 4)
                     (cons Events 8)))

(dm get-ptr>     ()      (: ptr))


(class +List)
(dm T (Prev Next)

  (=: ptr (native "@" "malloc" 'N (+ 8 8)))
  (struct (: ptr) 'N (cons Prev 8) (cons Next 8))
  (init>))

(dm get-ptr>     ()      (: ptr))
(dm init>        ()      (list-init        (: ptr)))
(dm insert>      (Elm)   (list-insert      (: ptr) (get-ptr> Elm)))
(dm remove>      (Elm)   (list-remove      (get-ptr> Elm)))
(dm length>      ()      (list-length      (: ptr)))
(dm empty>       ()      (list-empty       (: ptr)))
(dm insert-list> (Other) (list-insert-list (: ptr) (get-ptr> Other)))

(de list-init (List)              (native "libwayland-server.so" "wl_list_init" NIL List))
(de list-insert (List Elm)        (native "libwayland-server.so" "wl_list_insert" NIL List Elm))
(de list-remove (Elm)             (native "libwayland-server.so" "wl_list_remove" NIL Elm))
(de list-length (List)            (native "libwayland-server.so" "wl_list_length" 'I List))
(de list-empty (List)             (native "libwayland-server.so" "wl_list_empty" 'I List))
(de list-insert-list (List Other) (native "libwayland-server.so" "wl_list_insert_list" 'I List Other))


(class +Array)
(dm T (Size Alloc Data)

  (=: ptr (native "@" "malloc" 'N (+ 4 4 8)))
  (struct (: ptr) 'N (cons Size 4)
                     (cons Alloc 4)
                     (cons (get-ptr> Data) 8)))

(dm get-ptr>   ()      (: ptr))
(dm get-size>  () (struct    (: ptr)    'I))
(dm get-alloc> () (struct (+ (: ptr) 4) 'I))
(dm get-data>  () (struct (+ (: ptr) 8) 'N))
(dm get-ptr>   () (: ptr))

(dm init>    ()       (array-init (: ptr)))
(dm release> ()       (array-release (: ptr)))
(dm add>     (Size)   (array-add (: ptr) Size))
(dm copy>    (Source) (array-copy (: ptr) Source))

(de array-init    (Array)        (native "libwayland-server.so" "wl_array_init" NIL Array))
(de array-release (Array)        (native "libwayland-server.so" "wl_array_release" NIL Array))
(de array-add     (Array Size)   (native "libwayland-server.so" "wl_array_release" NIL Array Size))
(de array-copy    (Array Source) (native "libwayland-server.so" "wl_array_copy" 'I Array Source))