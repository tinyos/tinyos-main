/* async.c -- state management for asynchronous messages
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

/** 
 * @file async.c
 * @brief state management for asynchronous messages
 */

#ifndef WITHOUT_ASYNC

#include "config.h"

#include "utlist.h"

#include "mem.h"
#include "debug.h"
#include "async.h"

coap_async_state_t *
coap_register_async(coap_context_t *context, coap_address_t *peer,
		    coap_pdu_t *request, unsigned char flags, void *data) {
  coap_async_state_t *s;
  coap_opt_iterator_t opt_iter;
  coap_opt_t *token;
  coap_tid_t id;
  size_t toklen = 0;

  coap_transaction_id(peer, request, &id);
  LL_SEARCH_SCALAR(context->async_state,s,id,id);

  if (s != NULL) {
    /* We must return NULL here as the caller must know that he is
     * responsible for releasing @p data. */
    debug("asynchronous state for transaction %d already registered\n", id);
    return NULL;
  }

  token = coap_check_option(request, COAP_OPTION_TOKEN, &opt_iter);
  if (token)
    toklen = COAP_OPT_LENGTH(token);

  /* store information for handling the asynchronous task */
  s = (coap_async_state_t *)coap_malloc(sizeof(coap_async_state_t) + toklen);
  if (!s) {
#ifndef NDEBUG
    coap_log(LOG_CRIT, "coap_register_async: insufficient memory\n");
#endif
    return NULL;
  }

  memset(s, 0, sizeof(coap_async_state_t) + toklen);

  /* set COAP_ASYNC_CONFIRM according to request's type */
  s->flags = flags & ~COAP_ASYNC_CONFIRM;
  if (request->hdr->type == COAP_MESSAGE_CON)
    s->flags |= COAP_ASYNC_CONFIRM;

  s->appdata = data;

  memcpy(&s->peer, peer, sizeof(coap_address_t));

  if (toklen) {
    s->tokenlen = toklen;
    memcpy(s->token, COAP_OPT_VALUE(token), toklen);
  }

  //TODO: #ifdef TINYOS ?
  s->message_id = request->hdr->id;

  memcpy(&s->id, &id, sizeof(coap_tid_t));

  coap_touch_async(s);

  LL_PREPEND(context->async_state, s);

  return s;
}

coap_async_state_t *
coap_find_async(coap_context_t *context, coap_tid_t id) {
  coap_async_state_t *tmp;
  LL_SEARCH_SCALAR(context->async_state,tmp,id,id);  
  return tmp;
}

int
coap_remove_async(coap_context_t *context, coap_tid_t id, 
		  coap_async_state_t **s) {
  coap_async_state_t *tmp = coap_find_async(context, id);

  if (tmp)
    LL_DELETE(context->async_state,tmp);

  *s = tmp;
  return tmp != NULL;
}

void 
coap_free_async(coap_async_state_t *s) {
  if (s && (s->flags & COAP_ASYNC_RELEASE_DATA) != 0)
    coap_free(s->appdata);
  coap_free(s); 
}

#else
void does_not_exist();	/* make some compilers happy */
#endif /* WITHOUT_ASYNC */
