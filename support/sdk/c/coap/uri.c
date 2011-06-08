/* uri.c -- helper functions for URI treatment
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
#include <string.h>
#include <ctype.h>

#include "mem.h"
#include "debug.h"
#include "pdu.h"
#include "uri.h"

#ifndef MIN
# define MIN(x,y) (x) < (y) ? (x) : (y)
#endif

int
coap_split_uri(unsigned char *str_var, coap_uri_t *uri) {
  unsigned char *p;

  if ( !str_var || !uri )
    return -1;

  memset( uri, 0, sizeof(coap_uri_t) );

  /* find scheme */
  p = str_var;
  while ( isalnum(*p) )
    ++p;

  if ( *p != ':' ) {		/* no scheme, reset p */
    p = str_var;
  } else {			/* scheme found, check if it is "coap" */
    if (memcmp(str_var, COAP_DEFAULT_SCHEME, 
	       MIN(p - str_var, sizeof(COAP_DEFAULT_SCHEME) - 1)) != 0) {
#ifndef NDEBUG
      debug("unknown URI scheme '%s'\n", str_var);
#endif
      return -1;
    }
    *p++ = '\0';

    /* look for network authority */
    if ( strncmp( (char *)p, "//", 2 ) == 0 ) { /* have network authority */
      p += 2;
      uri->na.s = p;

      /* skip NA and port so that p and str_var finally point to path */
      while ( *p && *p != '/' && *p != '?') 
	++p;
      
      uri->na.length = p - uri->na.s;

      str_var = p;
#if 0
      /* split server address and port */
      if ( *uri->na == '[' ) {	/* IPv6 address reference */
	p = ++uri->na;

	while ( *p && *p != ']' ) 
	  ++p;
	*p++ = '\0';
      } else {			/* IPv4 address or hostname */
	p = uri->na;
	while ( *p && *p != ':' ) 
	  ++p;
      }
    
      if ( *p == ':' ) {	/* handle port */
	*p++ = '\0';
	uri->port = p;
      }
#endif
    } else 
      str_var = p;			

    /* str_var now points to the path or query if path is empty*/
  }

  /* split path and query */
  
  if ( *str_var == '\0' )
    return 0;

  if (*str_var != '?') {
    if (*str_var == '/')		/* skip leading '/' */
      *str_var++ = '\0';
    uri->path.s = str_var;
  }

  while (*str_var && *str_var != '?')
    str_var++;

  if (*str_var == '?') {
    *str_var++ = '\0';

    if (*str_var) {
      uri->query.s = str_var;
      uri->query.length = strlen((char *)uri->query.s);
    }
  } 

  if (uri->path.s)
    uri->path.length = strlen((char *)uri->path.s);

  return 0;
}

#define URI_DATA(uriobj) ((unsigned char *)(uriobj) + sizeof(coap_uri_t))

coap_uri_t *
coap_new_uri(const unsigned char *uri, unsigned int length) {
  unsigned char *result = coap_malloc(length + 1 + sizeof(coap_uri_t));
  if ( !result )
    return NULL;
  
  memcpy(URI_DATA(result), uri, length);
  URI_DATA(result)[length] = '\0'; /* make it zero-terminated */

  coap_split_uri( URI_DATA(result), (coap_uri_t *)result );
  return (coap_uri_t *)result;
}

coap_uri_t *
coap_clone_uri(const coap_uri_t *uri) {
  coap_uri_t *result;

  if ( !uri ) 
    return  NULL;

  result = (coap_uri_t *)coap_malloc( uri->query.length + uri->na.length + 
				      uri->path.length + sizeof(coap_uri_t) + 1);

  if ( !result )
    return NULL;

  memset( result, 0, sizeof(coap_uri_t) );

  if ( uri->na.length ) {
    result->na.s = URI_DATA(result);
    result->na.length = uri->na.length;

    memcpy(result->na.s, uri->na.s, uri->na.length);
  }

  if ( uri->path.length ) {
    result->path.s = URI_DATA(result) + uri->na.length;
    result->path.length = uri->path.length;

    memcpy(result->path.s, uri->path.s, uri->path.length);
  }

  if ( uri->query.length ) {
    result->query.s = URI_DATA(result) + uri->na.length + uri->path.length;
    result->query.length = uri->query.length;

    memcpy(result->query.s, uri->query.s, uri->query.length);
  }

  return result;
}
