/* str.c -- strings to be used in the CoAP library
 *
 * Copyright (C) 2010 Olaf Bergmann <bergmann@tzi.org>
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <stdio.h>

#include "mem.h"
#include "str.h"

str *coap_new_string(size_t size) {
  str *s = coap_malloc(sizeof(str) + size + 1);
  if ( !s ) {
#ifndef NDEBUG
    perror("coap_new_string: malloc");
#endif
    return NULL;
  }
    
  memset(s, 0, sizeof(str));
  s->s = ((unsigned char *)s) + sizeof(str);
  return s;
}

void coap_delete_string(str *s) {
  coap_free(s);
}

