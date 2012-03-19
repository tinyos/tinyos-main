/* resource.c -- generic resource handling
 *
 * Copyright (C) 2010--2012 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use.
 */

#include "config.h"
#include "net.h"
#include "debug.h"
#include "resource.h"
#include "subscribe.h"

#ifndef WITH_CONTIKI
#include "utlist.h" // for observe etc. this is also needed for TinyOS, possible to be replaced with coap_list???
#include "mem.h"
#endif /* WITH_CONTIKI */

#ifdef WITH_CONTIKI
#include "memb.h"

MEMB(resource_storage, coap_resource_t, COAP_MAX_RESOURCES);
MEMB(attribute_storage, coap_attr_t, COAP_MAX_ATTRIBUTES);
MEMB(subscription_storage, coap_subscription_t, COAP_MAX_SUBSCRIBERS);

void
coap_resources_init() {
  memb_init(&resource_storage);
  memb_init(&attribute_storage);
  memb_init(&subscription_storage);
}
#endif /* WITH_CONTIKI */

#ifdef WITH_TINYOS
//#include <coap_list.h>
//coap_list_t *resources;

/*
void
coap_resources_init() {
}
*/
#endif /* WITH_TINYOS */


#define min(a,b) ((a) < (b) ? (a) : (b))

/**
 * Prints the names of all known resources to @p buf. This function
 * sets @p buflen to the number of bytes actually written and returns
 * @c 1 on succes. On error, the value in @p buflen is undefined and
 * the return value will be @c 0.
 *
 * @param context The context with the resource map.
 * @param buf     The buffer to write the result.
 * @param buflen  Must be initialized to the maximum length of @p buf and will be
 *                set to the number of bytes written on return.
 *
 * @return @c 0 on error or @c 1 on success.
 */
int
print_wellknown(coap_context_t *context, unsigned char *buf, size_t *buflen) {
  coap_resource_t *r;
  unsigned char *p = buf;
  size_t left, written = 0;
#ifndef WITH_CONTIKI
  //#ifndef WITH_TINYOS
  coap_resource_t *tmp;

  HASH_ITER(hh, context->resources, r, tmp) {
      //#endif
#endif

#ifdef WITH_CONTIKI
  int i;

  r = (coap_resource_t *)resource_storage.mem;
  for (i = 0; i < resource_storage.num; ++i, ++r) {
    if (!resource_storage.count[i])
      continue;
#endif /* WITH_CONTIKI */

/* #ifdef WITH_TINYOS */
/*   coap_list_t *r_node; */

/*   for (r_node = context->resources; r_node; r_node = r_node->next ) { */
/*     r = r_node->data; */
/*     //r = (coap_resource_t*)r_node->data; */
/* #endif /\* WITH_CONTIKI *\/ */

    left = *buflen - written;

    if (left < *buflen) {	/* this is not the first resource  */
      *p++ = ',';
      --left;
    }

    if (!coap_print_link(r, p, &left))
      return 0;

    p += left;
    written += left;
  }
  *buflen = p - buf;
  return 1;
}

coap_resource_t *
coap_resource_init(const unsigned char *uri, size_t len) {
  coap_resource_t *r;

#ifndef WITH_CONTIKI
  r = (coap_resource_t *)coap_malloc(sizeof(coap_resource_t));
#endif /* WITH_CONTIKI */
#ifdef WITH_CONTIKI
  r = (coap_resource_t *)memb_alloc(&resource_storage);
#endif /* WITH_CONTIKI */

  if (r) {
    memset(r, 0, sizeof(coap_resource_t));

#ifdef WITH_CONTIKI
    LIST_STRUCT_INIT(r, link_attr);
    LIST_STRUCT_INIT(r, subscribers);
#endif /* WITH_CONTIKI */

    r->uri.s = (unsigned char *)uri;
    r->uri.length = len;

    coap_hash_path(r->uri.s, r->uri.length, r->key);
  } else {
    debug("coap_resource_init: no memory left\n");
  }

  return r;
}

coap_attr_t *
coap_add_attr(coap_resource_t *resource,
	      const unsigned char *name, size_t nlen,
	      const unsigned char *val, size_t vlen) {
  coap_attr_t *attr;

  if (!resource || !name)
    return NULL;

#ifndef WITH_CONTIKI
  attr = (coap_attr_t *)coap_malloc(sizeof(coap_attr_t));
#endif /* WITH_CONTIKI */
  // WITH_TINYOS: directly use ip_malloc of blip?

#ifdef WITH_CONTIKI
  attr = (coap_attr_t *)memb_alloc(&attribute_storage);
#endif /* WITH_CONTIKI */

  if (attr) {
    attr->name.length = nlen;
    attr->value.length = val ? vlen : 0;

    attr->name.s = (unsigned char *)name;
    attr->value.s = (unsigned char *)val;

    /* add attribute to resource list */
#ifndef WITH_CONTIKI
    LL_PREPEND(resource->link_attr, attr);
#endif /* WITH_CONTIKI */
  // WITH_TINYOS: directly use ip_malloc of blip?

#ifdef WITH_CONTIKI
    list_add(resource->link_attr, attr);
#endif /* WITH_CONTIKI */
  } else {
    debug("coap_add_attr: no memory left\n");
  }

  return attr;
}

void
coap_hash_request_uri(const coap_pdu_t *request, coap_key_t key) {
  coap_opt_iterator_t opt_iter;
  coap_opt_filter_t filter;

  memset(key, 0, sizeof(coap_key_t));

  coap_option_filter_clear(filter);
  coap_option_setb(filter, COAP_OPTION_URI_PATH);

  coap_option_iterator_init((coap_pdu_t *)request, &opt_iter, filter);
  while (coap_option_next(&opt_iter))
    coap_hash(COAP_OPT_VALUE(opt_iter.option),
	      COAP_OPT_LENGTH(opt_iter.option), key);
}

/*#ifdef WITH_TINYOS
int
order_resources(void *a, void *b) {
  if (!a || !b)
    return a < b ? -1 : 1;

  return -1;
#warning "correctly implement order_resources"
}
#endif*/

void
coap_add_resource(coap_context_t *context, coap_resource_t *resource) {
#ifndef WITH_CONTIKI
    //#ifndef WITH_TINYOS
  HASH_ADD(hh, context->resources, key, sizeof(coap_key_t), resource);
  //#endif /* WITH_TINYOS */
#endif /* WITH_CONTIKI */

      /*#ifdef WITH_TINYOS
  coap_list_t *r_node = coap_new_listnode(resource, NULL);
  coap_insert(&context->resources, r_node, order_resources);
  #endif*/
}

int
coap_delete_resource(coap_context_t *context, coap_key_t key) {
  coap_resource_t *resource;
#ifndef WITH_CONTIKI
  //#ifndef WITH_TINYOS
  coap_attr_t *attr, *tmp;
  //#endif
#endif
#ifdef WITH_CONTIKI
  coap_subscription_t *obs;
#endif

  if (!context)
    return 0;

  resource = coap_get_resource_from_key(context, key);

  if (!resource)
    return 0;

#ifndef WITH_CONTIKI
  //#ifndef WITH_TINYOS
  HASH_DELETE(hh, context->resources, resource);

  /* delete registered attributes */
  LL_FOREACH_SAFE(resource->link_attr, attr, tmp) coap_free(attr);

  coap_free(resource);
  //#endif
#endif

#ifdef WITH_CONTIKI
  /* delete registered attributes */
  while ( (attr = list_pop(resource->link_attr)) )
    memb_free(&attribute_storage, attr);

  /* delete subscribers */
  while ( (obs = list_pop(resource->subscribers)) ) {
    /* FIXME: notify observer that its subscription has been removed */
    memb_free(&subscription_storage, obs);
  }

  memb_free(&resource_storage, resource);
#endif /* WITH_CONTIKI */

  /*#ifdef WITH_TINYOS
#warning "implement delete resource"
#endif*/ /* WITH_TINYOS */

  return 1;
}

void led1On();

coap_resource_t *
coap_get_resource_from_key(coap_context_t *context, coap_key_t key) {
#ifndef WITH_CONTIKI
    //#ifndef WITH_TINYOS
  coap_resource_t *resource;
  HASH_FIND(hh, context->resources, key, sizeof(coap_key_t), resource);

  return resource;
  //#endif
#endif

#ifdef WITH_CONTIKI
  int i;
  coap_resource_t *ptr2;

  /* the search function is basically taken from memb.c */
  ptr2 = (coap_resource_t *)resource_storage.mem;
  for (i = 0; i < resource_storage.num; ++i) {
    if (resource_storage.count[i] &&
	(memcmp(ptr2->key, key, sizeof(coap_key_t)) == 0))
      return (coap_resource_t *)ptr2;
    ++ptr2;
  }

  return NULL;
#endif /* WITH_CONTIKI */

  /*
#ifdef WITH_TINYOS
  //TODO: go back to hashes? I was stupid!!!!!!!
  coap_list_t *r_node;
  coap_resource_t *r;


  for (r_node = context->resources; r_node; r_node = r_node->next ) {
    r = r_node->data;
    //r = (coap_resource_t*)r_node->data;
    if (memcmp(r->key, key, sizeof(coap_key_t)) == 0) {
      return (coap_resource_t *)r;
    }
  }
  return 0xff;
  #endif*/ /* WITH_TINYOS */
}

int
coap_print_link(const coap_resource_t *resource,
		unsigned char *buf, size_t *len) {
  unsigned char *p = buf;
  coap_attr_t *attr;

  size_t written = resource->uri.length + 3;
  if (*len < written)
    return 0;

  *p++ = '<';
  *p++ = '/';
  memcpy(p, resource->uri.s, resource->uri.length);
  p += resource->uri.length;
  *p++ = '>';

#ifndef WITH_CONTIKI
  LL_FOREACH(resource->link_attr, attr) {
#endif
#ifdef WITH_CONTIKI
  for (attr = list_head(resource->link_attr); attr;
       attr = list_item_next(attr)) {
#endif /* WITH_CONTIKI */
    written += attr->name.length + 1;
    if (*len < written)
      return 0;

    *p++ = ';';
    memcpy(p, attr->name.s, attr->name.length);
    p += attr->name.length;

    if (attr->value.s) {
      written += attr->value.length + 1;
      if (*len < written)
	return 0;

      *p++ = '=';
      memcpy(p, attr->value.s, attr->value.length);
      p += attr->value.length;
    }
  }
  if (resource->observeable && written + 4 <= *len) {
    memcpy(p, ";obs", 4);
    written += 4;
  }

  *len = written;
  return 1;
}

coap_subscription_t *
coap_find_observer(coap_resource_t *resource, const coap_address_t *peer,
		     const str *token) {
  coap_subscription_t *s;

  assert(resource);
  assert(peer);

#ifndef WITH_CONTIKI
  LL_FOREACH(resource->subscribers, s) {
#endif

#ifdef WITH_CONTIKI
  for (s = list_head(resource->subscribers); s; s = list_item_next(s)) {
#endif /* WITH_CONTIKI */

    if (coap_address_equals(&s->subscriber, peer)
	&& (!token || (token->length == s->token_length
		       && memcmp(token->s, s->token, token->length) == 0)))
      return s;
  }

  return NULL;
}

coap_subscription_t *
coap_add_observer(coap_resource_t *resource,
		  const coap_address_t *observer,
		  const str *token) {
  coap_subscription_t *s;

  assert(observer);

  /* Check if there is already a subscription for this peer. */
  s = coap_find_observer(resource, observer, token);

  /* We are done if subscription was found. */
  if (s)
    return s;

  /* s points to a different subscription, so we have to create
   * another one. */
#ifndef WITH_CONTIKI
  s = (coap_subscription_t *)coap_malloc(sizeof(coap_subscription_t));
#else /* WITH_CONTIKI */
  s = memb_alloc(&subscription_storage);
#endif /* WITH_CONTIKI */

  if (!s)
    return NULL;

  coap_subscription_init(s);
  memcpy(&s->subscriber, observer, sizeof(coap_address_t));

  if (token && token->length) {
    s->token_length = token->length;
    memcpy(s->token, token->s, min(s->token_length, 8));
  }

  /* add subscriber to resource */
#ifndef WITH_CONTIKI
  LL_PREPEND(resource->subscribers, s);
#endif

#ifdef WITH_CONTIKI
  list_add(resource->subscribers, s);
#endif /* WITH_CONTIKI */

  return s;
}

void
  coap_delete_observer(coap_resource_t *resource, coap_address_t *observer,
		       const str *token) {
  coap_subscription_t *s;

  s = coap_find_observer(resource, observer, token);

  if (s) {
#ifndef WITH_CONTIKI
    LL_DELETE(resource->subscribers, s);
#endif
#ifdef WITH_CONTIKI
    list_remove(resource->subscribers, s);
#endif /* WITH_CONTIKI */

    /* FIXME: notify observer that its subscription has been removed */
#ifndef WITH_CONTIKI
    coap_free(s);
#else /* WITH_CONTIKI */
    memb_free(&subscription_storage, s);
#endif /* WITH_CONTIKI */
  }
}


void
coap_check_notify(coap_context_t *context) {
  coap_resource_t *r;
  coap_pdu_t *response;
#ifndef WITH_CONTIKI
  //#ifndef WITH_TINYOS
  coap_resource_t *tmp;

  HASH_ITER(hh, context->resources, r, tmp) {
    if (r->observeable && r->dirty && r->subscribers) {
	//#endif
#endif

#ifdef WITH_CONTIKI
  int i;

  r = (coap_resource_t *)resource_storage.mem;
  for (i = 0; i < resource_storage.num; ++i, ++r) {
    if (!resource_storage.count[i] )
      continue;

    if (r->observeable && r->dirty && list_head(r->subscribers)) {
#endif /* WITH_CONTIKI */

	/*
#ifdef WITH_TINYOS
  coap_list_t *r_node;

  for (r_node = context->resources; r_node; r_node = r_node->next ) {
    r = r_node->data;
    //r = (coap_resource_t*)r_node->data;

    if (r->observeable && r->dirty && r->subscribers) {
    #endif*/ /* WITH_TINYOS */

      coap_method_handler_t h;

      /* retrieve GET handler, prepare response */
      h = r->handler[COAP_REQUEST_GET - 1];
      assert(h);		/* we do not allow subscriptions if no
				 * GET handler is defined */

      /* FIXME: provide CON/NON flag in coap_subscription_t */
      response = coap_pdu_init(COAP_MESSAGE_CON, 0, 0, COAP_MAX_PDU_SIZE);
      if (response) {
	coap_subscription_t *obs;
	str token;

#ifndef WITH_CONTIKI
      /* FIXME: */
	LL_FOREACH(r->subscribers, obs) {
#endif

#ifdef WITH_CONTIKI
      for (obs = list_head(r->subscribers); obs; obs = list_item_next(obs)) {
#endif /* WITH_CONTIKI */
	/* re-initialize response */

	token.length = obs->token_length;
	token.s = obs->token;

	coap_pdu_clear(response, response->max_size);
	response->hdr->id = coap_new_message_id(context);
	if (obs->non && obs->non_cnt < COAP_OBS_MAX_NON)
	  response->hdr->type = COAP_MESSAGE_NON;
	else
	  response->hdr->type = COAP_MESSAGE_CON;

	/* fill with observer-specific data */
	h(context, r, &obs->subscriber, NULL, &token, response);

	if (response->hdr->type == COAP_MESSAGE_CON) {
	  coap_send_confirmed(context, &obs->subscriber, response);
	  obs->non_cnt = 0;
	} else {
	  coap_send(context, &obs->subscriber, response);
	  obs->non_cnt++;
	}
      }
      coap_delete_pdu(response);

      /* Increment value for next Observe use. */
      context->observe++;
      }
    }
    r->dirty = 0;
  }
}

void
coap_handle_failed_notify(coap_context_t *context,
			  const coap_address_t *peer,
			  const str *token) {
#ifndef WITH_CONTIKI
  ;
#endif

  /*#ifdef WITH_TINYOS
  ;
  #endif*/

#ifdef WITH_CONTIKI
  //#ifndef WITH_TINYOS

  coap_resource_t *r;
  coap_subscription_t *obs;

  int i;

  r = (coap_resource_t *)resource_storage.mem;
  for (i = 0; i < resource_storage.num; ++i, ++r) {
    if (!resource_storage.count[i] )
      continue;

  again:
    for (obs = list_head(r->subscribers); obs; obs = list_item_next(obs)) {
      if (coap_address_equals(peer, &obs->subscriber) &&
	  token->length == obs->token_length &&
	  memcmp(token->s, obs->token, token->length) == 0) {

	/* FIXME: count failed notifies and remove when
	 * COAP_MAX_FAILED_NOTIFY is reached */
	if (obs->fail_cnt < COAP_OBS_MAX_FAIL)
	  obs->fail_cnt++;
	else {
	  list_remove(r->subscribers, obs);
	  obs->fail_cnt = 0;

	  debug("removed observer [%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x]:%d\r\n",
	      obs->subscriber.addr.u8[0], obs->subscriber.addr.u8[1],
	      obs->subscriber.addr.u8[2], obs->subscriber.addr.u8[3],
	      obs->subscriber.addr.u8[4], obs->subscriber.addr.u8[5],
	      obs->subscriber.addr.u8[6], obs->subscriber.addr.u8[7],
	      obs->subscriber.addr.u8[8], obs->subscriber.addr.u8[9],
	      obs->subscriber.addr.u8[10], obs->subscriber.addr.u8[11],
	      obs->subscriber.addr.u8[12], obs->subscriber.addr.u8[13],
	      obs->subscriber.addr.u8[14], obs->subscriber.addr.u8[15] ,
	      uip_ntohs(obs->subscriber.port));

	  memb_free(&subscription_storage, obs);
	  goto again;
	}
      }
    }
  }
  //#endif /* WITH_TINYOS */
#endif /* WITH_CONTIKI */
}
