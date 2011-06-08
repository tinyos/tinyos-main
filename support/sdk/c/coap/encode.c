/* encode.c -- encoding and decoding of CoAP data types
 *
 * Copyright (C) 2010 Olaf Bergmann <bergmann@tzi.org>, Carsten Bormann
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

#ifndef NDEBUG
#  include <stdio.h>
#endif

#include "encode.h"

/* Carsten suggested this when fls() is not available: */
int coap_fls(unsigned int i) {
  int n;
  for (n = 0; i; n++)
    i >>= 1;
  return n;
}

unsigned int
coap_decode_var_bytes(unsigned char *buf,unsigned int len) {
  unsigned int i, n = 0;
  for (i = 0; i < len; ++i)
    n = (n << 8) + buf[i]; 

  return n;
}

unsigned int
coap_encode_var_bytes(unsigned char *buf, unsigned int val) {
  int n, i = val >> 1;
  for (n = 0; i; n++)		/* FIXME: coap_fls() */
    i >>= 1;
 
  for (i = n / 8 + 1; i; --i) {
    buf[i-1] = val & 0xff;
    val >>= 8;
  }

  return n / 8 + 1;
}

