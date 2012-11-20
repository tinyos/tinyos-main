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

    if (COAP_OPT_ISJUMP(oi->option)) {
      oi->type = COAP_OPT_JUMP_VALUE(oi->option);
    } else {
      oi->type = COAP_OPT_DELTA(oi->option);
    }

    memcpy(oi->filter, filter, sizeof(coap_opt_filter_t));
    return oi;
  }

  return NULL;
}

#define opt_finished(oi) ((oi)->optcnt == COAP_OPT_LONG			\
			  ? ((oi)->option && *((oi)->option) == COAP_OPT_END) \
			  : (oi->n > (oi)->optcnt))

coap_opt_t *
coap_option_next(coap_opt_iterator_t *oi) {
  assert(oi);
  if (opt_finished(oi))
    return NULL;

  if (oi->n++) {
    oi->option = options_next(oi->option);
    if (COAP_OPT_ISJUMP(oi->option)) {
      oi->type += COAP_OPT_JUMP_VALUE(oi->option);
    } else {
      oi->type += COAP_OPT_DELTA(oi->option);
    }
  }

  /* proceed to next option */
  if (opt_finished(oi))
    return NULL;

  /* Skip subsequent options if it is a jump option or the filter bit
     is not set. */
  while (oi->option && (COAP_OPT_ISJUMP(oi->option)
			|| coap_option_getb(oi->filter, oi->type) == 0)) {
    if (!COAP_OPT_ISJUMP(oi->option)) {
      oi->n++;
    }

    /* proceed to next option */
    oi->option = options_next(oi->option);

    if (!oi->option || opt_finished(oi)) {
      return NULL;
    }

    if (COAP_OPT_ISJUMP(oi->option)) {
      oi->type += COAP_OPT_JUMP_VALUE(oi->option);
    } else {
      oi->type += COAP_OPT_DELTA(oi->option);
    }
  }

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
