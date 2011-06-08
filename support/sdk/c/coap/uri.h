/* uri.h -- helper functions for URI treatment
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

#ifndef _COAP_URI_H_
#define _COAP_URI_H_

#include "str.h"

typedef struct {
  str na;	/* network authority */
  str path;  	/* path */
  str query;	/* query part */
} coap_uri_t;

/**
 * Splits given URI into pieces and fills the specified uri object accordingly.
 * URI parts that are not available will be set to NULL in uri. The function 
 * returns -1 on error, 0 on success. Note that the passed str will be altered.
 */
int coap_split_uri(unsigned char *str_var, coap_uri_t *uri);

/**
 * Creates a new coap_uri_t object from the specified URI. Returns the new
 * object or NULL on error. The memory allocated by the new coap_uri_t 
 * must be released using coap_free(). 
 * @param uri The URI path to copy.
 * @para length The length of uri.
 * @return New URI object or NULL on error.
 */
coap_uri_t *coap_new_uri(const unsigned char *uri, unsigned int length);

/** 
 * Clones the specified coap_uri_t object. Thie function allocates sufficient
 * memory to hold the coap_uri_t structure and its contents. The object must
 * be released with coap_free(). */
coap_uri_t *coap_clone_uri(const coap_uri_t *uri);

#endif /* _COAP_URI_H_ */
