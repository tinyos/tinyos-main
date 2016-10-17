/* resource.c -- generic resource handling
 *
 * Copyright (C) 2010--2012 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

#include "config.h"
#include "net.h"
#include "coap_debug.h"
#include "resource.h"
#include "subscribe.h"

#ifndef WITH_CONTIKI
#include "utlist.h"
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

#define min(a,b) ((a) < (b) ? (a) : (b))

int
match(const str *text, const str *pattern, int match_prefix, int match_substring) {
  assert(text); assert(pattern);
  
  if (text->length < pattern->length)
    return 0;

  if (match_substring) {
    unsigned char *next_token = text->s;
    size_t remaining_length = text->length;
    while (remaining_length) {
      size_t token_length;
      unsigned char *token = next_token;
      next_token = memchr(token, ' ', remaining_length);

      if (next_token) {
        token_length = next_token - token;
        remaining_length -= (token_length + 1);
        next_token++;
      } else {
        token_length = remaining_length;
        remaining_length = 0;
      }
      
      if ((match_prefix || pattern->length == token_length) &&
            memcmp(token, pattern->s, pattern->length) == 0)
        return 1;
    }
    return 0;
  }

  return (match_prefix || pattern->length == text->length) &&
    memcmp(text->s, pattern->s, pattern->length) == 0;
}

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
 * @param query_filter A filter query according to <a href="http://tools.ietf.org/html/draft-ietf-core-link-format-11#section-4.1">Link Format</a>
 * 
 * @return @c 0 on error or @c 1 on success.
 */
#ifndef WITHOUT_WELLKNOWN
#if defined(__GNUC__) && defined(WITHOUT_QUERY_FILTER)
int
print_wellknown(coap_context_t *context, unsigned char *buf, size_t *buflen,
		coap_opt_t *query_filter __attribute__ ((unused))) {
#else /* not a GCC */
int
print_wellknown(coap_context_t *context, unsigned char *buf, size_t *buflen,
		coap_opt_t *query_filter) {
#endif /* GCC */
  coap_resource_t *r;
  unsigned char *p = buf;
  size_t left, written = 0;
  coap_resource_t *tmp;
#ifndef WITHOUT_QUERY_FILTER
  str resource_param = { 0, NULL }, query_pattern = { 0, NULL };
  int flags = 0; /* MATCH_SUBSTRING, MATCH_PREFIX, MATCH_URI */
  const str *rt_attributes;
#define MATCH_URI       0x01
#define MATCH_PREFIX    0x02
#define MATCH_SUBSTRING 0x04
  static const str _rt_attributes[] = {
    {2, (unsigned char *)"rt"},
    {2, (unsigned char *)"if"},
    {3, (unsigned char *)"rel"},
    {0, NULL}};
#endif /* WITHOUT_QUERY_FILTER */

#ifdef WITH_CONTIKI
  int i;
#endif /* WITH_CONTIKI */

#ifndef WITHOUT_QUERY_FILTER
  /* split query filter, if any */
  if (query_filter) {
    resource_param.s = COAP_OPT_VALUE(query_filter);
    while (resource_param.length < COAP_OPT_LENGTH(query_filter)
	   && resource_param.s[resource_param.length] != '=')
      resource_param.length++;
    
    if (resource_param.length < COAP_OPT_LENGTH(query_filter)) {
      if (resource_param.length == 4 && 
	  memcmp(resource_param.s, "href", 4) == 0)
	flags |= MATCH_URI;

      for (rt_attributes = _rt_attributes; rt_attributes->s; rt_attributes++) {
        if (resource_param.length == rt_attributes->length && 
            memcmp(resource_param.s, rt_attributes->s, rt_attributes->length) == 0) {
          flags |= MATCH_SUBSTRING;
          break;
        }
      }

      /* rest is query-pattern */
      query_pattern.s = 
	COAP_OPT_VALUE(query_filter) + resource_param.length + 1;

      assert((resource_param.length + 1) <= COAP_OPT_LENGTH(query_filter));
      query_pattern.length = 
	COAP_OPT_LENGTH(query_filter) - (resource_param.length + 1);

     if ((query_pattern.s[0] == '/') && ((flags & MATCH_URI) == MATCH_URI)) {
       query_pattern.s++;
       query_pattern.length--;
      }

      if (query_pattern.length && 
	  query_pattern.s[query_pattern.length-1] == '*') {
	query_pattern.length--;
	flags |= MATCH_PREFIX;
      }
    }
  }
#endif /* WITHOUT_QUERY_FILTER */

#ifndef WITH_CONTIKI

  HASH_ITER(hh, context->resources, r, tmp) {
#else /* WITH_CONTIKI */
  r = (coap_resource_t *)resource_storage.mem;
  for (i = 0; i < resource_storage.num; ++i, ++r) {
    if (!resource_storage.count[i])
      continue;
#endif /* WITH_CONTIKI */

#ifndef WITHOUT_QUERY_FILTER
    if (resource_param.length) { /* there is a query filter */
      
      if (flags & MATCH_URI) {	/* match resource URI */
	if (!match(&r->uri, &query_pattern, (flags & MATCH_PREFIX) != 0, (flags & MATCH_SUBSTRING) != 0))
	  continue;
      } else {			/* match attribute */
	coap_attr_t *attr;
        str unquoted_val;
	attr = coap_find_attr(r, NULL, resource_param.s, resource_param.length);
        if (!attr) continue;
        if (attr->value.s[0] == '"') {          /* if attribute has a quoted value, remove double quotes */
          unquoted_val.length = attr->value.length - 2;
          unquoted_val.s = attr->value.s + 1;
        } else {
          unquoted_val = attr->value;
        }
	if (!(match(&unquoted_val, &query_pattern,
		    (flags & MATCH_PREFIX) != 0,
                    (flags & MATCH_SUBSTRING) != 0)))
	  continue;
      }
    }
#endif /* WITHOUT_QUERY_FILTER */

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
#endif /* WITHOUT_WELLKNOWN */

coap_resource_t *
coap_resource_init(const unsigned char *uri, size_t len, int flags) {
  coap_resource_t *r;

#ifndef WITH_CONTIKI
  r = (coap_resource_t *)coap_malloc(sizeof(coap_resource_t));
#else /* WITH_CONTIKI */
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

    r->flags = flags;
  } else {
    debug("coap_resource_init: no memory left\n");
  }
  
  return r;
}

coap_attr_t *
coap_add_attr(coap_resource_t *resource, 
	      const unsigned char *name, size_t nlen,
	      const unsigned char *val, size_t vlen,
              int flags) {
  coap_attr_t *attr;

  if (!resource || !name)
    return NULL;

#ifndef WITH_CONTIKI
  attr = (coap_attr_t *)coap_malloc(sizeof(coap_attr_t));
#else /* WITH_CONTIKI */
  attr = (coap_attr_t *)memb_alloc(&attribute_storage);
#endif /* WITH_CONTIKI */

  if (attr) {
    attr->name.length = nlen;
    attr->value.length = val ? vlen : 0;

    attr->name.s = (unsigned char *)name;
    attr->value.s = (unsigned char *)val;

    attr->flags = flags;

    /* add attribute to resource list */
#ifndef WITH_CONTIKI
    LL_PREPEND(resource->link_attr, attr);
#else /* WITH_CONTIKI */
    list_add(resource->link_attr, attr);
#endif /* WITH_CONTIKI */
  } else {
    debug("coap_add_attr: no memory left\n");
  }
  
  return attr;
}

coap_attr_t *
coap_find_attr(coap_resource_t *resource, coap_attr_t * start_attr,
	       const unsigned char *name, size_t nlen) {
  coap_attr_t *attr;
  coap_attr_t *internal_start_attr;

  if (!resource || !name)
    return NULL;

  if (start_attr == NULL)
    internal_start_attr = resource->link_attr;
  else
    internal_start_attr = start_attr->next;

#ifndef WITH_CONTIKI
  LL_FOREACH(internal_start_attr, attr) {
#else /* WITH_CONTIKI */
  for (attr = list_head(internal_start_attr); attr;
       attr = list_item_next(attr)) {
#endif /* WITH_CONTIKI */
    if (attr->name.length == nlen &&
	memcmp(attr->name.s, name, nlen) == 0)
      return attr;
  }

  return NULL;
}

void
coap_delete_attr(coap_attr_t *attr) {
  if (!attr)
    return;
  if (attr->flags & COAP_ATTR_FLAGS_RELEASE_NAME)
    coap_free(attr->name.s);
  if (attr->flags & COAP_ATTR_FLAGS_RELEASE_VALUE)
    coap_free(attr->value.s);
  coap_free(attr);
}

void
coap_hash_request_uri(const coap_pdu_t *request, coap_key_t key) {
  coap_opt_iterator_t opt_iter;
  coap_opt_filter_t filter;
  coap_opt_t *option;

  memset(key, 0, sizeof(coap_key_t));

  coap_option_filter_clear(filter);
  coap_option_setb(filter, COAP_OPTION_URI_PATH);

  coap_option_iterator_init((coap_pdu_t *)request, &opt_iter, filter);
  while ((option = coap_option_next(&opt_iter)))
    coap_hash(COAP_OPT_VALUE(option), COAP_OPT_LENGTH(option), key);
}

void
coap_add_resource(coap_context_t *context, coap_resource_t *resource) {
#ifndef WITH_CONTIKI
  HASH_ADD(hh, context->resources, key, sizeof(coap_key_t), resource);
#endif /* WITH_CONTIKI */
}

int
coap_delete_resource(coap_context_t *context, coap_key_t key) {
  coap_resource_t *resource;
  coap_attr_t *attr, *tmp;
#ifdef WITH_CONTIKI
  coap_subscription_t *obs;
#endif

  if (!context)
    return 0;

  resource = coap_get_resource_from_key(context, key);

  if (!resource) 
    return 0;
    
#ifndef WITH_CONTIKI
  HASH_DELETE(hh, context->resources, resource);

  /* delete registered attributes */
  LL_FOREACH_SAFE(resource->link_attr, attr, tmp) coap_delete_attr(attr);

  if (resource->flags & COAP_RESOURCE_FLAGS_RELEASE_URI)
    coap_free(resource->uri.s);

  coap_free(resource);
#else /* WITH_CONTIKI */
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

  return 1;
}

coap_resource_t *
coap_get_resource_from_key(coap_context_t *context, coap_key_t key) {
#ifndef WITH_CONTIKI
  coap_resource_t *resource;
  HASH_FIND(hh, context->resources, key, sizeof(coap_key_t), resource);

  return resource;
#else /* WITH_CONTIKI */
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
#else /* WITH_CONTIKI */
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
  if (resource->observable && written + 4 <= *len) {
    memcpy(p, ";obs", 4);
    written += 4;
  }

  *len = written;
  return 1;
}

#ifndef WITHOUT_OBSERVE
coap_subscription_t *
coap_find_observer(coap_resource_t *resource, const coap_address_t *peer,
		     const str *token) {
  coap_subscription_t *s;

  assert(resource);
  assert(peer);

#ifndef WITH_CONTIKI
  LL_FOREACH(resource->subscribers, s) {
#else /* WITH_CONTIKI */
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
#else /* WITH_CONTIKI */
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
#else /* WITH_CONTIKI */
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
  coap_resource_t *tmp;

  HASH_ITER(hh, context->resources, r, tmp) {
    if (r->observable && r->dirty && r->subscribers) {
#else /* WITH_CONTIKI */
  int i;
  
  r = (coap_resource_t *)resource_storage.mem;
  for (i = 0; i < resource_storage.num; ++i, ++r) {
    if (!resource_storage.count[i] )
      continue;

    if (r->observable && r->dirty && list_head(r->subscribers)) {
#endif /* WITH_CONTIKI */
      coap_method_handler_t h;
      coap_subscription_t *obs;
      str token;

      /* retrieve GET handler, prepare response */
      h = r->handler[COAP_REQUEST_GET - 1];
      assert(h);		/* we do not allow subscriptions if no
				 * GET handler is defined */

#ifndef WITH_CONTIKI
      /* FIXME: */
      LL_FOREACH(r->subscribers, obs) {
#else /* WITH_CONTIKI */
      for (obs = list_head(r->subscribers); obs; obs = list_item_next(obs)) {
#endif /* WITH_CONTIKI */
        coap_tid_t tid = COAP_INVALID_TID;
	/* initialize response */
        response = coap_pdu_init(COAP_MESSAGE_CON, 0, 0, COAP_MAX_PDU_SIZE);
        if (!response) {
          debug("coap_check_notify: pdu init failed\n");
          continue;
        }
	if (!coap_add_token(response, obs->token_length, obs->token)) {
	  debug("coap_check_notify: cannot add token\n");
	  coap_delete_pdu(response);
	  continue;
	}

	token.length = obs->token_length;
	token.s = obs->token;

	response->hdr->id = coap_new_message_id(context);
	if (obs->non && obs->non_cnt < COAP_OBS_MAX_NON)
	  response->hdr->type = COAP_MESSAGE_NON;
	else
	  response->hdr->type = COAP_MESSAGE_CON;

	/* fill with observer-specific data */
	h(context, r, &obs->subscriber, NULL, &token, response);

	if (response->hdr->type == COAP_MESSAGE_CON) {
	  tid = coap_send_confirmed(context, &obs->subscriber, response);
	  obs->non_cnt = 0;
	} else {
	  tid = coap_send(context, &obs->subscriber, response);
	  obs->non_cnt++;
	}

        if (COAP_INVALID_TID == tid || response->hdr->type != COAP_MESSAGE_CON)
          coap_delete_pdu(response);
      }

      /* Increment value for next Observe use. */
      context->observe++;
    }
    r->dirty = 0;
  }
}

#ifndef WITH_CONTIKI
void
coap_handle_failed_notify(coap_context_t *context __attribute__((__unused__)),
			  const coap_address_t *peer __attribute__((__unused__)),
			  const str *token __attribute__((__unused__))) {
}
#else /* WITH_CONTIKI */
void
coap_handle_failed_notify(coap_context_t *context,
			  const coap_address_t *peer,
			  const str *token) {
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
	      obs->subscriber.addr.u8[14], obs->subscriber.addr.u8[15],
	      uip_ntohs(obs->subscriber.port));

	  memb_free(&subscription_storage, obs);
	  goto again;
	}
      }
    }
  }
}
#endif /* WITH_CONTIKI */

#endif /* WITHOUT_NOTIFY */
