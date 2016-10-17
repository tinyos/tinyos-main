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

#include "coap_debug.h"
#include "block.h"

#define min(a,b) ((a) < (b) ? (a) : (b))

#ifndef WITHOUT_BLOCK
int
coap_get_block(coap_pdu_t *pdu, unsigned short type, coap_block_t *block) {
  coap_opt_iterator_t opt_iter;
  coap_opt_t *option;

  assert(block);
  memset(block, 0, sizeof(coap_block_t));

  if (pdu && (option = coap_check_option(pdu, type, &opt_iter))) {
    block->szx = COAP_OPT_BLOCK_SZX(option);
    if (COAP_OPT_BLOCK_MORE(option))
      block->m = 1;
    block->num = COAP_OPT_BLOCK_NUM(option);

    return 1;
  }

  return 0;
}

int
coap_write_block_opt(coap_block_t *block, unsigned short type,
		     coap_pdu_t *pdu, size_t data_length) {
  size_t start, want, avail;
  unsigned char buf[3];

  assert(pdu);

  /* Block2 */
  if (type != COAP_OPTION_BLOCK2) {
    warn("coap_write_block_opt: skipped unknown option\n");
    return -1;
  }

  start = block->num << (block->szx + 4);
  if (data_length <= start) {
    debug("illegal block requested\n");
    return -2;
  }
  
  avail = pdu->max_size - pdu->length - 4;
  want = 1 << (block->szx + 4);

  /* check if entire block fits in message */
  if (want <= avail) {
    block->m = want < data_length - start;
  } else {
    /* Sender has requested a block that is larger than the remaining
     * space in pdu. This is ok if the remaining data fits into the pdu
     * anyway. The block size needs to be adjusted only if there is more
     * data left that cannot be delivered in this message. */

    if (data_length - start <= avail) {

      /* it's the final block and everything fits in the message */
      block->m = 0;
    } else {
      unsigned char szx;

      /* we need to decrease the block size */
      if (avail < 16) { 	/* bad luck, this is the smallest block size */
	debug("not enough space, even the smallest block does not fit");
	return -3;
      }
      debug("decrease block size for %d to %d\n", avail, coap_fls(avail) - 5);
      szx = block->szx;
      block->szx = coap_fls(avail) - 5;
      block->m = 1;
      block->num <<= szx - block->szx;
    }
  }

  /* to re-encode the block option */
  coap_add_option(pdu, type, coap_encode_var_bytes(buf, ((block->num << 4) | 
							 (block->m << 3) | 
							 block->szx)), 
		  buf);

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
#endif /* WITHOUT_BLOCK  */
