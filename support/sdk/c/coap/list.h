/* list.h -- CoAP list structures
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

#ifndef _COAP_LIST_H_
#define _COAP_LIST_H_

struct coap_linkedlistnode {
  struct coap_linkedlistnode *next;
  void *data;

  /**
   * Callback function that is called from coap_delete to release
   * additional memory allocated by data Set to NULL if you do not
   * need this. Note that data is free'd automatically. */
  void (*delete)(void *);
};

typedef struct coap_linkedlistnode coap_list_t;

/**
 * Adds node to given queue, ordered by specified order function. Returns 1
 * when insert was successful, 0 otherwise.
 */
int coap_insert(coap_list_t **queue, coap_list_t *node, 
		int (*order)(void *, void *) );

/* destroys specified node */
int coap_delete(coap_list_t *node);

/* removes all items from given queue and frees the allocated storage */
void coap_delete_list(coap_list_t *queue);

/**
 * Creates a new list node and adds the given data object. The memory allocated
 * by data will be released by coap_delete() with the new node. Returns the
 * new list node.
 */
coap_list_t *coap_new_listnode(void *data, void (*delete)(void *) );

#endif /* _COAP_LIST_H_ */
