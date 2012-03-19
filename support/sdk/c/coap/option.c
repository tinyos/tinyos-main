/*
 * option.c -- helpers for handling options in CoAP PDUs
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */


#include "config.h"

#if defined(HAVE_ASSERT_H) && !defined(assert)
# include <assert.h>
#endif

#ifndef assert
//#warning "assertions are disabled"
#  define assert(x)
#endif

#include <stdio.h>

#include "option.h"


const coap_opt_filter_t COAP_OPT_ALL = 
  { 0xff, 0xff, 0xff };	       /* must be sizeof(coap_opt_filter_t) */

coap_opt_iterator_t *
coap_option_iterator_init(coap_pdu_t *pdu, coap_opt_iterator_t *oi,
			  const coap_opt_filter_t filter) {
  assert(pdu); assert(oi);
  
  memset(oi, 0, sizeof(coap_opt_iterator_t));
  if (pdu->hdr->optcnt) {
    oi->optcnt = pdu->hdr->optcnt;
    oi->option = options_start(pdu);
    oi->type = COAP_OPT_DELTA(oi->option);
    memcpy(oi->filter, filter, sizeof(coap_opt_filter_t));
    return oi;
  } 
  
  return NULL;
}

#define IS_EMPTY_NOOP(Type,Option) \
  ((Type) % COAP_OPTION_NOOP == 0 && COAP_OPT_LENGTH(Option) == 0)

coap_opt_t *
coap_option_next(coap_opt_iterator_t *oi) {

  if (!oi || oi->n >= oi->optcnt)
    return NULL;

  if (oi->n++) {
    oi->option = options_next(oi->option);
    oi->type += COAP_OPT_DELTA(oi->option);
  }
  
  /* Skip subsequent options if it is an empty no-op (used for
   * fence-posting) or the filter bit is not set. */
  while (oi->n <= oi->optcnt && 
	 (IS_EMPTY_NOOP(oi->type, oi->option)
	  || coap_option_getb(oi->filter, oi->type) == 0)) {
    oi->n++;
    oi->option = options_next(oi->option);

    if (oi->n > oi->optcnt)
      break;

    oi->type += COAP_OPT_DELTA(oi->option);
  }
  
  if (oi->n > oi->optcnt)
    oi->option = NULL;

  return oi->option;
}

coap_opt_t *
coap_check_option(coap_pdu_t *pdu, unsigned char type, 
		  coap_opt_iterator_t *oi) {
  coap_opt_filter_t f;
  
  memset(f, 0, sizeof(coap_opt_filter_t));
  coap_option_setb(f, type);

  coap_option_iterator_init(pdu, oi, f);

  coap_option_next(oi);

  return oi->option && oi->type == type ? oi->option : NULL;
}
