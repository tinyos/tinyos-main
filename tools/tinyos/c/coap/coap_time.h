/* coap_time.h -- Clock Handling
 *
 * Copyright (C) 2010,2011 Olaf Bergmann <bergmann@tzi.org>
 *
 * This file is part of the CoAP library libcoap. Please see
 * README for terms of use. 
 */

/** 
 * @file coap_time.h
 * @brief Clock Handling
 */

#ifndef _COAP_TIME_H_
#define _COAP_TIME_H_

#include "config.h"

/**
 * @defgroup clock Clock Handling
 * Default implementation of internal clock. You should redefine this if
 * you do not have time() and gettimeofday().
 * @{
 */

#ifdef WITH_CONTIKI
#include "clock.h"

typedef clock_time_t coap_tick_t;

#define COAP_TICKS_PER_SECOND CLOCK_SECOND

/** Set at startup to initialize the internal clock (time in seconds). */
extern clock_time_t clock_offset;

static inline void
contiki_clock_init_impl(void) {
  clock_init();
  clock_offset = clock_time();
}

#define coap_clock_init contiki_clock_init_impl

static inline void
contiki_ticks_impl(coap_tick_t *t) {
  *t = clock_time();
}

#define coap_ticks contiki_ticks_impl

#endif /* WITH_CONTIKI */

#ifdef WITH_TINYOS
//#include "clock.h"

//typedef clock_time_t coap_tick_t;
typedef uint32_t coap_tick_t;

//#define COAP_TICKS_PER_SECOND CLOCK_SECOND
#define COAP_TICKS_PER_SECOND 1

/** Set at startup to initialize the internal clock (time in seconds). */
extern uint32_t clock_offset;

inline void tinyos_clock_init_impl(void);
#define coap_clock_init tinyos_clock_init_impl

inline void tinyos_ticks_impl(coap_tick_t *t);
#define coap_ticks tinyos_ticks_impl

#endif /* WITH_TINYOS */

#ifndef WITH_CONTIKI
#ifndef WITH_TINYOS
typedef unsigned int coap_tick_t;

#define COAP_TICKS_PER_SECOND 1024

/** Set at startup to initialize the internal clock (time in seconds). */
extern time_t clock_offset;
#endif
#endif

#ifndef coap_clock_init
static inline void
coap_clock_init_impl(void) {
#ifdef HAVE_TIME_H
  clock_offset = time(NULL);
#else
#  ifdef __GNUC__
    /* Issue a warning when using gcc. Other prepropressors do 
     *  not seem to have a similar feature. */ 
#   warning "cannot initialize clock"
#  endif
  clock_offset = 0;
#endif
}
#define coap_clock_init coap_clock_init_impl
#endif /* coap_clock_init */

#ifndef coap_ticks
static inline void
coap_ticks_impl(coap_tick_t *t) {
#ifdef HAVE_SYS_TIME_H
  struct timeval tv;
  gettimeofday(&tv, NULL);
  *t = (tv.tv_sec - clock_offset) * COAP_TICKS_PER_SECOND 
    + (tv.tv_usec * COAP_TICKS_PER_SECOND / 1000000);
#else
#error "clock not implemented"
#endif
}
#define coap_ticks coap_ticks_impl
#endif /* coap_ticks */

/** @} */

#endif /* _COAP_TIME_H_ */
