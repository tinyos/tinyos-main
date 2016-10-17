/* subscribe.c -- subscription handling for CoAP
 *                see draft-hartke-coap-observe-03
 *
 * Copyright (C) 2010--2012 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

#include "config.h"

#if defined(HAVE_ASSERT_H) && !defined(assert)
# include <assert.h>
#endif

#include <stdio.h>
#include <limits.h>
#ifdef HAVE_ARPA_INET_H
# include <arpa/inet.h>
#endif

/* #include "resource.h" */

#include "mem.h"
#include "encode.h"
#include "coap_debug.h"
#include "subscribe.h"

void
coap_subscription_init(coap_subscription_t *s) {
  assert(s);
  memset(s, 0, sizeof(coap_subscription_t));
}

#if 0
#define HMASK (ULONG_MAX >> 1)

void
notify(coap_context_t *context, coap_resource_t *res,
       coap_subscription_t *sub, unsigned int duration, int code) {
#if 0
  coap_pdu_t *pdu;
  int ls, finished=0;
  unsigned char ct, d;
  unsigned int length;
#ifndef NDEBUG
  char addr[INET6_ADDRSTRLEN];
#endif

  if ( !context || !res || !sub || !(pdu = coap_new_pdu()) )
    return;

  pdu->hdr->type = COAP_MESSAGE_CON;
  pdu->hdr->id = rand();	/* use a random transaction id */
  pdu->hdr->code = code;

  /* FIXME: content-type and data (how about block?) */
  if (res->uri->host.length)
    coap_add_option (pdu, COAP_OPTION_URI_HOST,
		     res->uri->host.length,
		     res->uri->host.s );

  if (res->uri->path.length)
    coap_add_option (pdu, COAP_OPTION_URI_PATH,
		     res->uri->path.length,
		     res->uri->path.s);

  d = COAP_PSEUDOFP_ENCODE_8_4_DOWN(duration, ls);

  coap_add_option ( pdu, COAP_OPTION_SUBSCRIPTION, 1, &d );

  if (sub->token.length) {
    coap_add_option (pdu, COAP_OPTION_TOKEN,
		     sub->token.length,
		     sub->token.s);
  }

  if (res->uri->query.length)
    coap_add_option (pdu, COAP_OPTION_URI_QUERY,
		     res->uri->query.length,
		     res->uri->query.s );

  if (res->data) {
    length = (unsigned char *)pdu->hdr + COAP_MAX_PDU_SIZE - pdu->data;
    ct = res->mediatype;
    res->data(res->uri, &ct, 0, pdu->data, &length, &finished);
    pdu->length += length;

    /* TODO: add block option if not finished */
    /* TODO: add mediatype */
  }

#ifndef NDEBUG
  if ( inet_ntop(sub->subscriber.addr.sa.sa_family, 
		 &sub->subscriber.addr, addr, sizeof(addr)) ) {
    debug("*** notify for %s to [%s]\n", res->uri->path.s, addr);
  }
#endif
  if (pdu && coap_send_confirmed(context,
				 &sub->subscriber.addr.sa,
				 sub->subscriber.size, pdu) 
      == COAP_INVALID_TID) {
#ifndef NDEBUG
    debug("coap_check_resource_list: error sending notification\n");
#endif
    coap_delete_pdu(pdu);
  }
#endif
}

void
coap_check_resource_list(coap_context_t *context) {
  coap_resource_t *res, *tmp;
  coap_list_t *sub;
  coap_key_t key;
  time_t now;

  if ( !context || !context->resources /* || !context->subscribers */)
    return;

  time(&now);			/* FIXME: use coap_ticks() */

  HASH_ITER(hh, context->resources, res, tmp) {
    if (res->dirty) {
      debug("FIXME: notify subscribers\n");
#if 0
      key = coap_uri_hash( COAP_RESOURCE(res)->uri ) ;

      /* is subscribed? */
      for (sub = context->subscriptions; sub; sub = sub->next) {
	if ( COAP_SUBSCRIPTION(sub)->resource == key ) {
	  /* notify subscriber */
	  notify(context, COAP_RESOURCE(res), COAP_SUBSCRIPTION(sub),
		 COAP_SUBSCRIPTION(sub)->expires - now, COAP_RESPONSE_200);
	}

      }

      COAP_RESOURCE(res)->dirty = 0;
#endif
    }
  }
}

#if 0
coap_resource_t *
coap_get_resource_from_key(coap_context_t *ctx, coap_key_t key) {
  coap_list_t *node;

  if (ctx) {
    /* TODO: use hash table for resources with key to access */
    for (node = ctx->resources; node; node = node->next) {
      printf("check %ux\n", coap_uri_hash(COAP_RESOURCE(node)->uri));
      if ( key == coap_uri_hash(COAP_RESOURCE(node)->uri) ) {
	printf("found\n");
	return COAP_RESOURCE(node);
      }
    }
  }

  printf("not found\n");
  return NULL;
}

coap_resource_t *
coap_get_resource(coap_context_t *ctx, coap_uri_t *uri) {
#ifndef NDEBUG
  int i;
  printf("search resource %ux", coap_uri_hash(uri));
  for (i=0; i < uri->path.length; ++i) {
    printf(" %02x", uri->path.s[i]);
  }
  printf("\n");
#endif
  return uri ? coap_get_resource_from_key(ctx, coap_uri_hash(uri)) : NULL;
}
#endif

void
coap_check_subscriptions(coap_context_t *context) {
  time_t now;
  coap_list_t *node;
#ifndef NDEBUG
  char addr[INET6_ADDRSTRLEN];
#endif

  if ( !context )
    return;

  time(&now);

  node = context->subscriptions;
  while ( node && COAP_SUBSCRIPTION(node)->expires < now ) {
#ifndef NDEBUG
    if (inet_ntop(COAP_SUBSCRIPTION(node)->subscriber.addr.sa.sa_family,
		  &COAP_SUBSCRIPTION(node)->subscriber.addr,
		  addr, sizeof(addr))) {
      
      debug("** removed expired subscription from [%s]\n", addr);
    }
#endif
#if 0
    notify(context,
	   coap_get_resource_from_key(context, COAP_SUBSCRIPTION(node)->resource),
	   COAP_SUBSCRIPTION(node),
	   0, COAP_RESPONSE_400);
#endif
    context->subscriptions = node->next;
    coap_delete(node);
    node = context->subscriptions;
  }
}

void
coap_free_resource(void *res) {
  if ( res ) {
#if 0
    coap_free(((coap_resource_t *)res)->uri);
    coap_delete_string(((coap_resource_t *)res)->name);
#endif
  }
}

#if 0
/**
 * Deletes the resource that is identified by key. Returns 1 if the resource was
 * removed, 0 on error (e.g. if no such resource exists).
 */
int
coap_delete_resource(coap_context_t *context, coap_key_t key) {
  coap_list_t *prev, *node;

  if (!context || key == COAP_INVALID_HASHKEY)
    return 0;

  for (prev = NULL, node = context->resources; node;
       prev = node, node = node->next) {
    if (coap_uri_hash(COAP_RESOURCE(node)->uri) == key) {
#ifndef NDEBUG
      debug("removed key %lu (%s)\n",key,COAP_RESOURCE(node)->uri->path.s);
#endif
      if (!prev)
	context->resources = node->next;
      else
	prev->next = node->next;

      coap_delete(node);
      return 1;
    }
  }
  return 0;
}
#endif

coap_subscription_t *
coap_new_subscription(coap_context_t *context, const coap_uri_t *resource,
		      const struct sockaddr *addr, socklen_t addrlen, time_t expiry) {
  coap_subscription_t *result;

  if ( !context || !resource || !addr
       || !(result = coap_malloc(sizeof(coap_subscription_t))))
    return NULL;

  result->resource = coap_uri_hash(resource);
  result->expires = expiry;
  memcpy(&result->subscriber.addr.sa, addr, addrlen);

  memset(&result->token, 0, sizeof(str));

  return result;

}

coap_list_t *
coap_list_push_first(coap_list_t **list, void *data, void (*delete_func)(void *) ) {
  coap_list_t *node;
  node = coap_new_listnode(data, delete_func);
  if ( !node || !list )
    return NULL;

  if ( !*list ) {
    *list = node;
  } else {
    node->next = *list;
    *list = node;
  }

  return node;
}

int
_order_subscription(void *a, void *b) {
  if ( !a || !b )
    return a < b ? -1 : 1;

  return ((coap_subscription_t *)a)->expires < ((coap_subscription_t *)b)->expires ? -1 : 1;
}

coap_key_t
coap_subscription_hash(coap_subscription_t *subscription) {
  if ( !subscription )
    return COAP_INVALID_HASHKEY;

  return _hash2( subscription->resource, (unsigned char *)&subscription->subscriber,
		 sizeof(subscription->subscriber) );
}

coap_key_t
coap_add_subscription(coap_context_t *context,
		      coap_subscription_t *subscription) {
  coap_list_t *node;
  if ( !context || !subscription )
    return COAP_INVALID_HASHKEY;

  if ( !(node = coap_new_listnode(subscription, NULL)) )
    return COAP_INVALID_HASHKEY;

  if ( !coap_insert(&context->subscriptions, node, _order_subscription ) ) {
    coap_free( node );	/* do not call coap_delete(), so subscription object will survive */
    return COAP_INVALID_HASHKEY;
  }

  return coap_subscription_hash(subscription);
}

coap_subscription_t *
coap_find_subscription(coap_context_t *context,
		       coap_key_t hashkey,
		       struct sockaddr *addr,
		       str *token) {
#if 0
  coap_list_t *node;
#endif

  if (!context || !addr || hashkey == COAP_INVALID_HASHKEY)
    return NULL;

  /* FIXME: I do not like the way subscriptions work right now. To be fixed. */

#if 0
  for (node = context->subscriptions; node; node = node->next) {
    if (COAP_SUBSCRIPTION(node)->resource == hashkey) {

      if (token) {	   /* do not proceed if tokens do not match */
	if (token->length != COAP_SUBSCRIPTION(node)->token.length ||
	    memcmp(token->s, COAP_SUBSCRIPTION(node)->token.s,
		   token->length) != 0)
	  continue;
      }

      if (subscriber->sin6_port == COAP_SUBSCRIPTION(node)->subscriber.sin6_port
	  && memcmp(&subscriber->sin6_addr,
		    &COAP_SUBSCRIPTION(node)->subscriber.sin6_addr,
		    sizeof(struct in6_addr)) == 0)
	return COAP_SUBSCRIPTION(node);
    }
  }
#endif
  return NULL;
}

int
coap_delete_subscription(coap_context_t *context,
			 coap_key_t key,
			 struct sockaddr *addr) {
#if 0
  coap_list_t *prev, *node;
#endif

  if (!context || !addr || key == COAP_INVALID_HASHKEY)
    return 0;

  /* FIXME: I do not like the way subscriptions work right now. To be fixed. */

#if 0
  for (prev = NULL, node = context->subscriptions; node;
       prev = node, node = node->next) {
    if (COAP_SUBSCRIPTION(node)->resource == key) {
      if (subscriber->sin6_port == COAP_SUBSCRIPTION(node)->subscriber.sin6_port
	  && memcmp(&subscriber->sin6_addr,
		    &COAP_SUBSCRIPTION(node)->subscriber.sin6_addr,
		    sizeof(struct in6_addr)) == 0) {

	if (!prev) {
	  context->subscriptions = node->next;
	  coap_free(COAP_SUBSCRIPTION(node)->token.s);
	  coap_delete(node);
	} else {
	  prev->next = node->next;
	  coap_free(COAP_SUBSCRIPTION(node)->token.s);
	  coap_delete(node);
	}
	return 1;
      }
    }
  }
#endif

  return 0;
}
#endif
