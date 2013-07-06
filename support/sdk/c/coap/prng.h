/* prng.h -- Pseudo Random Numbers
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

/** 
 * @file prng.h
 * @brief Pseudo Random Numbers
 */

#ifndef _COAP_PRNG_H_
#define _COAP_PRNG_H_

#include "config.h"

/**
 * @defgroup prng Pseudo Random Numbers
 * @{
 */

#ifndef WITH_CONTIKI
#ifndef WITH_TINYOS
#include <stdlib.h>

/**
 * Fills \p buf with \p len random bytes. This is the default
 * implementation for prng().  You might want to change prng() to use
 * a better PRNG on your specific platform.
 */
static inline int
coap_prng_impl(unsigned char *buf, size_t len) {
  while (len--)
    *buf++ = rand() & 0xFF;
  return 1;
}
#endif /* WITH_TINYOS */
#endif /* WITH_CONTIKI */

#ifdef WITH_CONTIKI
#include <string.h>

/**
 * Fills \p buf with \p len random bytes. This is the default
 * implementation for prng().  You might want to change prng() to use
 * a better PRNG on your specific platform.
 */
static inline int
contiki_prng_impl(unsigned char *buf, size_t len) {
  unsigned short v = random_rand();
  while (len > sizeof(v)) {
    memcpy(buf, &v, sizeof(v));
    len -= sizeof(v);
    buf += sizeof(v);
  }

  memcpy(buf, &v, len);
  return 1;
}

#define prng(Buf,Length) contiki_prng_impl((Buf), (Length))
#define prng_init(Value) random_init((unsigned short)(Value))
#endif /* WITH_CONTIKI */

#ifdef WITH_TINYOS
/**
 */
inline int tinyos_prng_impl(unsigned char *buf, size_t len);

static inline int
tinyos_prng_init(unsigned short value) {
  return 1;
}

#define prng(Buf,Length) tinyos_prng_impl((Buf), (Length))
#define prng_init(Value) tinyos_prng_init((unsigned short)(Value))

#endif

#ifndef prng
/** 
 * Fills \p Buf with \p Length bytes of random data. 
 * 
 * @hideinitializer
 */
#define prng(Buf,Length) coap_prng_impl((Buf), (Length))
#endif

#ifndef prng_init
/** 
 * Called to set the PRNG seed. You may want to re-define this to
 * allow for a better PRNG.
 *
 * @hideinitializer
 */
#define prng_init(Value) srand((unsigned long)(Value))
#endif

/** @} */

#endif /* _COAP_PRNG_H_ */
