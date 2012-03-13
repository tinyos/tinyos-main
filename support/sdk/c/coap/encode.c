/* encode.c -- encoding and decoding of CoAP data types
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 * 
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

#ifndef NDEBUG
#  include <stdio.h>
#endif

#include "config.h"
#include "encode.h"

/* Carsten suggested this when fls() is not available: */
int coap_fls(unsigned int i) {
  int n;
  for (n = 0; i; n++)
    i >>= 1;
  return n;
}

unsigned int
coap_decode_var_bytes(unsigned char *buf,unsigned int len) {
  unsigned int i, n = 0;
  for (i = 0; i < len; ++i)
    n = (n << 8) + buf[i]; 

  return n;
}

unsigned int
coap_encode_var_bytes(unsigned char *buf, unsigned int val) {
  int n, i = val >> 1;
  for (n = 0; i; n++)		/* FIXME: coap_fls() */
    i >>= 1;
 
  for (i = n / 8 + 1; i; --i) {
    buf[i-1] = val & 0xff;
    val >>= 8;
  }

  return n / 8 + 1;
}

