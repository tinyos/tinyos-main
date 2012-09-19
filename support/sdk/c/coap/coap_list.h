/* coap_list.h -- CoAP list structures
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
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
  void (*delete_func)(void *);
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
coap_list_t *coap_new_listnode(void *data, void (*delete_func)(void *) );

#endif /* _COAP_LIST_H_ */
