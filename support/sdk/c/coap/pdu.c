/* pdu.c -- CoAP message structure
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#ifdef IDENT_APPNAME
#include <lib6lowpan/nwbyte.h>
#else
#include <arpa/inet.h>
#endif

#include "debug.h"
#include "mem.h"
#include "pdu.h"


coap_pdu_t *
coap_new_pdu() {
  coap_pdu_t *pdu = coap_malloc( sizeof(coap_pdu_t) + COAP_MAX_PDU_SIZE );
  if (!pdu) {
#ifndef IDENT_APPNAME
    perror("new_pdu: malloc");
#endif
    return NULL;
  }
  
  /* initialize PDU */
  memset(pdu, 0, sizeof(coap_pdu_t) + COAP_MAX_PDU_SIZE );
  pdu->hdr = (coap_hdr_t *) ( (unsigned char *)pdu + sizeof(coap_pdu_t) );
  pdu->hdr->version = COAP_DEFAULT_VERSION;
  pdu->hdr->id = ntohs( COAP_INVALID_TID );

  /* data points after the header; when options are added, the data 
     pointer is moved to the back */
  pdu->length = sizeof(coap_hdr_t);
  pdu->data = (unsigned char *)pdu->hdr + pdu->length;

  return pdu;
}

void 
coap_delete_pdu(coap_pdu_t *pdu) {
  coap_free( pdu );
}

#define options_start(p) ((coap_opt_t *) ( (unsigned char *)p->hdr + sizeof ( coap_hdr_t ) ))

int 
coap_add_option(coap_pdu_t *pdu, unsigned char type, unsigned int len, const unsigned char *data) {
  unsigned char cnt;
  coap_opt_t *opt;
  unsigned char opt_code = 0;

  if (!pdu) 
    return -1;

  /* get last option from pdu to calculate the delta */
  
  opt = options_start( pdu );
  for ( cnt = pdu->hdr->optcnt; cnt; --cnt ) {
    opt_code += COAP_OPT_DELTA(*opt);
    opt = (coap_opt_t *)( (unsigned char *)opt + COAP_OPT_SIZE(*opt) ); 
  }

  if ( type < opt_code ) {
#ifndef NDEBUG
    fprintf(stderr, "options not added in correct order\n");
#endif
    return -1;
  }

  /* Create new option after last existing option: First check if we
   * need fence posts between type and last opt_code (i.e. delta >
   * 15), and then add actual option.
   */

  while (type - opt_code > 15) {
    cnt = opt_code / COAP_OPTION_NOOP;

    /* add fence post */
    pdu->hdr->optcnt += 1;
    COAP_OPT_SETLENGTH( *opt, 0 );
    COAP_OPT_SETDELTA( *opt, (COAP_OPTION_NOOP * (cnt+1)) - opt_code );

    opt_code += COAP_OPT_DELTA(*opt);
    opt = (coap_opt_t *)( (unsigned char *)opt + COAP_OPT_SIZE(*opt) ); 
  }

  /* here, the actual option is added (delta <= 15) */
  pdu->hdr->optcnt += 1;
  COAP_OPT_SETDELTA( *opt, type - opt_code );
  
  COAP_OPT_SETLENGTH( *opt, len );
  memcpy(COAP_OPT_VALUE(*opt), data, len);
  pdu->data = (unsigned char *)COAP_OPT_VALUE(*opt) + len ;

  pdu->length = pdu->data - (unsigned char *)pdu->hdr;
  return len;
}

coap_opt_t *
coap_check_option(coap_pdu_t *pdu, unsigned char type) {
  unsigned char cnt;
  coap_opt_t *opt;
  unsigned char opt_code = 0;

  if (!pdu) 
    return NULL;

  /* get last option from pdu to calculate the delta */
  
  opt = options_start( pdu );
  for ( cnt = pdu->hdr->optcnt; cnt && opt_code < type; --cnt ) {
    opt_code += COAP_OPT_DELTA(*opt);
    
    /* check if current option is the one we are looking for */
    if (type == opt_code)
      return opt;		/* yes, return */

    /* goto next option */
    opt = (coap_opt_t *)( (unsigned char *)opt + COAP_OPT_SIZE(*opt) ); 
  }

  return NULL;
}

int
coap_check_critical(coap_pdu_t *pdu, coap_opt_t **option) {
  unsigned char cnt;
  unsigned char opt_code = 0;

  if (!pdu) 
    goto success;

  /* get last option from pdu to calculate the delta */
  
  *option = options_start( pdu );
  for ( cnt = pdu->hdr->optcnt; cnt; --cnt ) {
    opt_code += COAP_OPT_DELTA(**option);
    
    /* check if current option is critical */
    if (opt_code & 0x01) {
      switch (opt_code) {	/* skip known options */
      case COAP_OPTION_CONTENT_TYPE :
      case COAP_OPTION_URI_AUTHORITY :
      case COAP_OPTION_URI_PATH :
      case COAP_OPTION_TOKEN :
      case COAP_OPTION_BLOCK :
      case COAP_OPTION_URI_QUERY :
	break;
      default:			/* return first unknown critical option */
#ifndef NDEBUG
	fprintf(stderr, 
		"coap_check_critical: unknown critical option %d\n", opt_code);
#endif
	return opt_code;
      }
    }

    /* goto next option */
    *option = (coap_opt_t *)( (unsigned char *)*option + COAP_OPT_SIZE(**option) ); 
  }

 success:
  *option = NULL;
  return 0;
}

int 
coap_add_data(coap_pdu_t *pdu, unsigned int len, const unsigned char *data) {
  if ( !pdu )
    return 0;
  
  if ( pdu->length + len > COAP_MAX_PDU_SIZE ) {
#ifndef NDEBUG
    fprintf(stderr, "coap_add_data: cannot add: data too large for PDU\n");
#endif
    return 0;
  }

  memcpy( (unsigned char *)pdu->hdr + pdu->length, data, len );
  pdu->length += len;
  return 1;
}

int 
coap_get_data(coap_pdu_t *pdu, unsigned int *len, unsigned char **data) {
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

int 
coap_get_request_uri(coap_pdu_t *pdu, coap_uri_t *result) {
  coap_opt_t *opt;
  
  if (!pdu || !result)
    return 0;

  memset(result, 0, sizeof(*result));

  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_AUTHORITY))) 
    COAP_SET_STR(&result->na, COAP_OPT_LENGTH(*opt), COAP_OPT_VALUE(*opt));

  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_PATH))) 
    COAP_SET_STR(&result->path, COAP_OPT_LENGTH(*opt), COAP_OPT_VALUE(*opt));

  if ((opt = coap_check_option(pdu, COAP_OPTION_URI_QUERY))) 
    COAP_SET_STR(&result->query, COAP_OPT_LENGTH(*opt), COAP_OPT_VALUE(*opt));

  return 1;
}

#if 0
int 
coap_encode_pdu(coap_pdu_t *pdu) {

}
#endif
