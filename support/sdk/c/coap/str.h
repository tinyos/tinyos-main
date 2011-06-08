/* str.h -- strings to be used in the CoAP library
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

#ifndef _COAP_STR_H_
#define _COAP_STR_H_

#include <string.h>

typedef struct {
  size_t length;		/* length of string */
  unsigned char *s;		/* string data */
} str;

#define COAP_SET_STR(st,l,v) { (st)->length = (l), (st)->s = (v); }

/**
 * Returns a new string object with at least size bytes storage
 * allocated.  The string must be released using coap_delete_string();
 */ 
str *coap_new_string(size_t size);

/** Deletes the given string and releases any memory allocated. */
void coap_delete_string(str *);

#endif /* _COAP_STR_H_ */
