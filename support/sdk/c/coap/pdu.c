/* pdu.c -- CoAP message structure
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifdef HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif

#ifdef WITH_TINYOS
#include <lib6lowpan/nwbyte.h> // for ntohs()
#endif

#include "debug.h"
#include "pdu.h"
#include "option.h"
#include "encode.h"

#ifdef WITH_CONTIKI
#include "memb.h"

typedef unsigned char _pdu[sizeof(coap_pdu_t) + COAP_MAX_PDU_SIZE];

MEMB(pdu_storage, _pdu, COAP_PDU_MAXCNT);

void
coap_pdu_resources_init() {
  memb_init(&pdu_storage);
}
#else /* WITH_CONTIKI */
#include "mem.h"
#endif /* WITH_CONTIKI */

void
coap_pdu_clear(coap_pdu_t *pdu, size_t size) {
  assert(pdu);

  memset(pdu, 0, sizeof(coap_pdu_t) + size);
  pdu->max_size = size;
  pdu->hdr = (coap_hdr_t *)((unsigned char *)pdu + sizeof(coap_pdu_t));
  pdu->hdr->version = COAP_DEFAULT_VERSION;

  /* data points after the header; when options are added, the data
     pointer is moved to the back */
  pdu->length = sizeof(coap_hdr_t);
  pdu->data = (unsigned char *)pdu->hdr + pdu->length;
}

coap_pdu_t *
coap_pdu_init(unsigned char type, unsigned char code, 
	      unsigned short id, size_t size) {
  coap_pdu_t *pdu;

  assert(size <= COAP_MAX_PDU_SIZE);
  /* Size must be large enough to fit the header. */
  if (size < sizeof(coap_hdr_t) || size > COAP_MAX_PDU_SIZE)
    return NULL;

  /* size must be large enough for hdr */
#ifndef WITH_CONTIKI
  pdu = coap_malloc(sizeof(coap_pdu_t) + size);
#else /* WITH_CONTIKI */
  pdu = (coap_pdu_t *)memb_alloc(&pdu_storage);
#endif /* WITH_CONTIKI */
  if (pdu) {
    coap_pdu_clear(pdu, size);
    pdu->hdr->id = id;
    pdu->hdr->type = type;
    pdu->hdr->code = code;
  } 
  return pdu;
}

coap_pdu_t *
coap_new_pdu() {
  coap_pdu_t *pdu;
  
#ifndef WITH_CONTIKI
  pdu = coap_pdu_init(0, 0, ntohs(COAP_INVALID_TID), COAP_MAX_PDU_SIZE);
#else /* WITH_CONTIKI */
  pdu = coap_pdu_init(0, 0, uip_ntohs(COAP_INVALID_TID), COAP_MAX_PDU_SIZE);
#endif /* WITH_CONTIKI */

#ifndef NDEBUG
  if (!pdu)
    coap_log(LOG_CRIT, "coap_new_pdu: cannot allocate memory for new PDU\n");
#endif
  return pdu;
}

void
coap_delete_pdu(coap_pdu_t *pdu) {
#ifndef WITH_CONTIKI
  coap_free( pdu );
#else /* WITH_CONTIKI */
  memb_free(&pdu_storage, pdu);
#endif /* WITH_CONTIKI */
}

coap_pdu_t *
coap_clone_pdu(coap_pdu_t *pdu) {
  coap_pdu_t *cloned_pdu;
  size_t data_len;
  unsigned char *data;

  cloned_pdu = coap_pdu_init(0, 0, ntohs(COAP_INVALID_TID), COAP_MAX_PDU_SIZE);

  if (!pdu)
    return NULL;

  memcpy(cloned_pdu->hdr, pdu->hdr, sizeof(coap_hdr_t));

  if (pdu->hdr->optcnt) {
    coap_opt_iterator_t opt_iter;
    coap_option_iterator_init((coap_pdu_t *)pdu, &opt_iter, COAP_OPT_ALL);

    while (coap_option_next(&opt_iter)) {
      coap_add_option(cloned_pdu, opt_iter.type,
                     COAP_OPT_LENGTH(opt_iter.option),
                     COAP_OPT_VALUE(opt_iter.option));
    }
  }

  if(coap_get_data(pdu, &data_len, &data))
    coap_add_data(cloned_pdu, data_len, data);

  return cloned_pdu;
}

int
coap_add_option(coap_pdu_t *pdu, unsigned short type, unsigned int len, const unsigned char *data) {
  size_t optsize, cnt;
  unsigned short opt_code = 0;
  coap_opt_t *opt;
  
  if (!pdu)
    return -1;

  debug("add option %d (%d bytes)\n", type, len);
  /* Get last option from pdu to calculate the delta. For optcnt ==
   * 0x0F, opt will point at the end marker, so the new option will
   * overwrite it.
   */
  opt = options_start(pdu);
  cnt = pdu->hdr->optcnt;
  while ((pdu->hdr->optcnt == COAP_OPT_LONG && opt &&
	  opt < ((unsigned char *)pdu->hdr + pdu->max_size) && 
	  *opt != COAP_OPT_END)
	 || cnt--) {
    opt_code += COAP_OPT_DELTA(opt);
    opt = options_next(opt);
  }

  if ((unsigned char *)pdu->hdr + pdu->max_size <= (unsigned char *)opt) {
    debug("illegal option list\n");
    return -1;
  }

  optsize = (unsigned char *)pdu->hdr + pdu->max_size - opt;
  if (pdu->hdr->optcnt + 1 >= COAP_OPT_LONG) {
    /* need an additional byte to store the end marker */
    optsize--;
  }
  /* at this point optsize might be zero */
  
  if ( type < opt_code ) {
#ifndef NDEBUG
    coap_log(LOG_WARN, "options not added in correct order\n");
#endif
    return -1;
  }

  cnt = coap_opt_encode(opt, optsize, type - opt_code, data, len);

  if (!cnt) {
    warn("cannot add option %u\n", type);
    /* nothing has changed in opt, therefore we do not have to restore
     * optcnt, data, or end-of-options marker */
    return -1;
  }

  opt += cnt;			/* advance opt behind the option */
  pdu->hdr->optcnt++;		/* can we rely on the compiler to trim
				 * this down to 4 bits? */
  assert(pdu->hdr->optcnt <= 15);

  if (pdu->hdr->optcnt == COAP_OPT_LONG) {
    /* Before calling coap_opt_encode(), we have made sure that the
     * end-of-options marker fits in, so no new check is required. */
    *opt++ = COAP_OPT_END;
  }

  pdu->data = (unsigned char *)opt;
  pdu->length = pdu->data - (unsigned char *)pdu->hdr;
  return len;
}

int
coap_add_data(coap_pdu_t *pdu, unsigned int len, const unsigned char *data) {
  if ( !pdu )
    return 0;

  if ( pdu->length + len > pdu->max_size ) {
#ifndef NDEBUG
 coap_log(LOG_WARN, "coap_add_data: cannot add: data too large for PDU\n");
#endif
    return 0;
  }

  memcpy( (unsigned char *)pdu->hdr + pdu->length, data, len );
  pdu->length += len;
  return 1;
}

int
coap_get_data(coap_pdu_t *pdu, size_t *len, unsigned char **data) {
  if ( !pdu )
    return 0;

  if ( pdu->data < (unsigned char *)pdu->hdr + pdu->length ) {
    /* pdu contains data */

    *len = (unsigned char *)pdu->hdr + pdu->length - pdu->data;
    *data = pdu->data;
  } else {			/* no data, clear everything */
    *len = 0;
    *data = NULL;
  }

  return 1;
}

#ifndef SHORT_ERROR_RESPONSE
typedef struct {
  unsigned char code;
  char *phrase;
} error_desc_t;

/* if you change anything here, make sure, that the longest string does not 
 * exceed COAP_ERROR_PHRASE_LENGTH. */
error_desc_t coap_error[] = {
  { COAP_RESPONSE_CODE(65),  "2.01 Created" },
  { COAP_RESPONSE_CODE(66),  "2.02 Deleted" },
  { COAP_RESPONSE_CODE(67),  "2.03 Valid" },
  { COAP_RESPONSE_CODE(68),  "2.04 Changed" },
  { COAP_RESPONSE_CODE(69),  "2.05 Content" },
  { COAP_RESPONSE_CODE(400), "Bad Request" },
  { COAP_RESPONSE_CODE(401), "Unauthorized" },
  { COAP_RESPONSE_CODE(402), "Bad Option" },
  { COAP_RESPONSE_CODE(403), "Forbidden" },
  { COAP_RESPONSE_CODE(404), "Not Found" },
  { COAP_RESPONSE_CODE(405), "Method Not Allowed" },
  { COAP_RESPONSE_CODE(408), "Request Entity Incomplete" },
  { COAP_RESPONSE_CODE(413), "Request Entity Too Large" },
  { COAP_RESPONSE_CODE(415), "Unsupported Media Type" },
  { COAP_RESPONSE_CODE(500), "Internal Server Error" },
  { COAP_RESPONSE_CODE(501), "Not Implemented" },
  { COAP_RESPONSE_CODE(502), "Bad Gateway" },
  { COAP_RESPONSE_CODE(503), "Service Unavailable" },
  { COAP_RESPONSE_CODE(504), "Gateway Timeout" },
  { COAP_RESPONSE_CODE(505), "Proxying Not Supported" },
  { 0, NULL }			/* end marker */
};

char *
coap_response_phrase(unsigned char code) {
  int i;
  for (i = 0; coap_error[i].code; ++i) {
    if (coap_error[i].code == code)
      return coap_error[i].phrase;
  }
  return NULL;
}
#endif

//#if 0
int
coap_get_request_uri(coap_pdu_t *pdu, coap_uri_t *result) {
  coap_opt_t *opt;
  coap_opt_iterator_t opt_iter;
  
  if (!pdu || !result)
    return 0;

  memset(result, 0, sizeof(*result));
    
  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_HOST, &opt_iter)))
    COAP_SET_STR(&result->host, COAP_OPT_LENGTH(opt), COAP_OPT_VALUE(opt));

  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_PORT, &opt_iter)))
    result->port = 
      coap_decode_var_bytes(COAP_OPT_VALUE(opt), COAP_OPT_LENGTH(opt));
  else
    result->port = COAP_DEFAULT_PORT;

  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_PATH, &opt_iter))) {
    result->path.s = COAP_OPT_VALUE(opt);
    result->path.length = COAP_OPT_LENGTH(opt);

    while (coap_option_next(&opt_iter) && opt_iter.type == COAP_OPTION_URI_PATH) 
      result->path.length += COAP_OPT_SIZE(opt_iter.option);
  }

  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_QUERY, &opt_iter))) {
    result->query.s = COAP_OPT_VALUE(opt);
    result->query.length = COAP_OPT_LENGTH(opt);

    while (coap_option_next(&opt_iter) && opt_iter.type == COAP_OPTION_URI_QUERY) 
      result->query.length += COAP_OPT_SIZE(opt_iter.option);
  }

  return 1;
}
//#endif
