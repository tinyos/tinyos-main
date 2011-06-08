/* list.c -- CoAP list structures
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

#include "mem.h"
#include "list.h"

int
coap_insert(coap_list_t **queue, coap_list_t *node,
	    int (*order)(void *, void *node) ) {
  coap_list_t *p, *q;
  if ( !queue || !node )
    return 0;
    
  /* set queue head if empty */
  if ( !*queue ) {
    *queue = node;
    return 1;
  }

  /* replace queue head if new node has to be added before the existing queue head */
  q = *queue;
  if ( order( node->data, q->data ) < 0) {
    node->next = q;
    *queue = node;
    return 1;
  }

  /* search for right place to insert */
  do {
    p = q;
    q = q->next;
  } while ( q && order( node->data, q->data ) >= 0);
  
  /* insert new item */
  node->next = q;
  p->next = node;
  return 1;
}

int 
coap_delete(coap_list_t *node) {
  if ( !node ) 
    return 0;

  if ( node->delete ) 
    node->delete( node->data );
  coap_free( node->data );
  coap_free( node );  

  return 1;
}

void
coap_delete_list(coap_list_t *queue) {
  if ( !queue ) 
    return;

  coap_delete_list( queue->next );
  coap_delete( queue );
}

coap_list_t *
coap_new_listnode(void *data, void (*delete)(void *) ) {
  coap_list_t *node = coap_malloc( sizeof(coap_list_t) );
  if ( ! node ) {
#ifndef IDENT_APPNAME
    perror ("coap_new_listnode: malloc");
#endif
    return NULL;
  }

  memset(node, 0, sizeof(coap_list_t));
  node->data = data;
  node->delete = delete;
  return node;
}

