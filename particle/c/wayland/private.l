#{
/* Generated by wayland-scanner 1.17.0 */

/*
 * Copyright © 2008-2011 Kristian Høgsberg
 * Copyright © 2010-2011 Intel Corporation
 * Copyright © 2012-2013 Collabora, Ltd.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
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

(def 'types 0)

#{
static const struct wl_interface *types[] = {
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	&wl_callback_interface,
	&wl_registry_interface,
	&wl_surface_interface,
	&wl_region_interface,
	&wl_buffer_interface,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	&wl_shm_pool_interface,
	NULL,
	NULL,
	&wl_data_source_interface,
	&wl_surface_interface,
	&wl_surface_interface,
	NULL,
	&wl_data_source_interface,
	NULL,
	&wl_data_offer_interface,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	&wl_data_offer_interface,
	&wl_data_offer_interface,
	&wl_data_source_interface,
	&wl_data_device_interface,
	&wl_seat_interface,
	&wl_shell_surface_interface,
	&wl_surface_interface,
	&wl_seat_interface,
	NULL,
	&wl_seat_interface,
	NULL,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
	&wl_output_interface,
	&wl_seat_interface,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	NULL,
	&wl_output_interface,
	&wl_buffer_interface,
	NULL,
	NULL,
	&wl_callback_interface,
	&wl_region_interface,
	&wl_region_interface,
	&wl_output_interface,
	&wl_output_interface,
	&wl_pointer_interface,
	&wl_keyboard_interface,
	&wl_touch_interface,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	NULL,
	&wl_surface_interface,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	&wl_surface_interface,
	NULL,
	NULL,
	NULL,
	&wl_subsurface_interface,
	&wl_surface_interface,
	&wl_surface_interface,
	&wl_surface_interface,
	&wl_surface_interface,
};
}#

#{
  interface-* defined in wayland-private         (prot vers)
  *-interface defined in wayland-server-protocol (fn ptrs)
  Both are generated from XML/scanner
}#

(def '*requests-compositor (list (new '(+Message) "create_surface" "n" (+ ptr-types 10))
                                 (new '(+Message) "create_region"  "n" (+ ptr-types 11))))
(def '*requests-shell      (list (new '(+Message) "get_shell_surface" "no" (+ ptr-types 37))))
(def '*requests-seat       (list (new '(+Message) "get_pointer" "n" (+ ptr-types 66))
                                 (new '(+Message) "get_keyboard" "n" (+ ptr-types 67))
                                 (new '(+Message) "get_touch" "n" (+ ptr-types 68))
                                 (new '(+Message) "release" "n" (+ ptr-types 0))))
(def '*events-seat         (list (new '(+Message) "capabilities" "u" (+ ptr-types 0))
                                 (new '(+Message) "name" "2s" (+ ptr-types 0))))

(def '*interface-compositor  (new '(+Interface) "wl_compositor" 4 2 *requests-compositor 0 0))
(def '*interface-shell       (new '(+Interface) "wl_shell" 1 1 *requests-shell 0 0))
(def '*interface-seat        (new '(+Interface) "wl_seat" 7 4 *requests-seat 2 *events-seat))

(def '*interface-buffer (new '(+Interface)))
(def '*interface-callback (new '(+Interface)))
(def '*interface-data-device (new '(+Interface)))
(def '*interface-data-offer (new '(+Interface)))
(def '*interface-data-source (new '(+Interface)))
(def '*interface-keyboard (new '(+Interface)))
(def '*interface-output (new '(+Interface)))
(def '*interface-pointer (new '(+Interface)))
(def '*interface-region (new '(+Interface)))
(def '*interface-registry (new '(+Interface)))
#(def '*interface-seat (new '(+Interface)))
(def '*interface-shell-surface (new '(+Interface)))
(def '*interface-shm-pool (new '(+Interface)))
(def '*interface-subsurface (new '(+Interface)))
(def '*interface-surface (new '(+Interface)))
(def '*interface-touch (new '(+Interface)))