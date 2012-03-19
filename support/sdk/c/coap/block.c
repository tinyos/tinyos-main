/* block.c -- block transfer
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

#ifndef assert
//#warning "assertions are disabled"
#  define assert(x)
#endif

#include "debug.h"
#include "block.h"

#define min(a,b) ((a) < (b) ? (a) : (b))

int
coap_write_block_opt(coap_opt_t **block_req, unsigned short type,
		     coap_pdu_t *pdu, size_t data_length) {
  coap_block_t block;
  size_t start, want, avail;

  assert(pdu); assert(block_req && *block_req);

  if (type != COAP_OPTION_BLOCK2) {
    warn("coap_write_block_opt: skipped unknown option\n");
    return -1;
  }

  /* Block2 */
  block.szx = COAP_OPT_BLOCK_SZX(*block_req);
  block.m = COAP_OPT_BLOCK_MORE(*block_req);
  block.num = COAP_OPT_BLOCK_NUM(*block_req);

  start = block.num << (block.szx + 4);
  if (data_length <= start) {
    debug("illegal block requested\n");
    return -2;
  }

  avail = pdu->max_size - pdu->length - 4;
  want = 1 << (block.szx + 4);

  /* check if entire block fits in message */
  if (want <= avail) {
    coap_opt_block_set_m(*block_req, want <= data_length - start);
    coap_add_option(pdu, type,
		    COAP_OPT_LENGTH(*block_req), COAP_OPT_VALUE(*block_req));
  } else {
    /* Sender has requested a block that is larger than the remaining
     * space in pdu. This is ok if the remaining data fits into the pdu
     * anyway. The block size needs to be adjusted only if there is more
     * data left that cannot be delivered in this message. */

    if (data_length - start <= avail) {

      /* it's the final block and everything fits in the message */
      coap_opt_block_set_m(*block_req, 0);
      coap_add_option(pdu, type,
		      COAP_OPT_LENGTH(*block_req), COAP_OPT_VALUE(*block_req));
    } else {
      unsigned char buf[3];

      /* we need to decrease the block size */
      if (avail < 16) { 	/* bad luck, this is the smallest block size */
	debug("not enough space, even the smallest block does not fit");
	return -3;
      }
      debug("decrease block size for %d to %d\n", avail, coap_fls(avail) - 5);
      block.szx = coap_fls(avail) - 5;
      block.m = 1;
      block.num <<= COAP_OPT_BLOCK_SZX(*block_req) - block.szx;

      /* as the block number changes, we need to re-encode the block
       * option */
      coap_add_option(pdu, type, coap_encode_var_bytes(buf,
            (block.num << 4) | (block.m << 3) | block.szx), buf);
      {
	coap_opt_iterator_t oi;
	*block_req = coap_check_option(pdu, type, &oi);
      }
    }
  }

  return 1;
}

int
coap_add_block(coap_pdu_t *pdu, unsigned int len, const unsigned char *data,
	       unsigned int block_num, unsigned char block_szx) {
  size_t start;
  start = block_num << (block_szx + 4);

  if (len <= start)
    return 0;

  return coap_add_data(pdu,
		       min(len - start, (unsigned int)(1 << (block_szx + 4))),
		       data + start);
}
