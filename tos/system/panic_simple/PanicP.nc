/*
 * Copyright (c) 2012-2013, 2016 Eric B. Decker
 * All rights reserved.
 *
 * This module provides a simple Panic interface.   It currently
 * does nothing but provides a place where Panics can be seen (like
 * from a debugger).
 *
 * it could be easily be extended to something a little more useful
 * like blinking a specific led to indicate a Panic failure.
 */

#include "panic.h"

#ifndef bkpt
#warning bkpt not defined, using default nothingness
#define bkpt() do {} while (0)
#endif

#ifdef notdef
#ifdef PANIC_DINT
#define MAYBE_SAVE_SR_AND_DINT	do {	\
    if (save_sr_free) {			\
      save_sr = READ_SR;		\
      save_sr_free = FALSE;		\
    }					\
    dint();				\
} while (0);
#else
#define MAYBE_SAVE_SR_AND_DINT	do {} while (0)
#endif
#endif


module PanicP {
  provides {
    interface Panic;
    interface Init;
  }
}

implementation {
  parg_t save_sr;
  bool save_sr_free;
  norace uint8_t _p, _w;
  norace parg_t _a0, _a1, _a2, _a3, _arg;

  /* if a double panic, high order bit is set */
  norace bool m_in_panic;               /* initialized to 0 */

  void debug_break(parg_t arg)  __attribute__ ((noinline)) {
    _arg = arg;
    bkpt();
  }


  async command void Panic.warn(uint8_t pcode, uint8_t where,
        parg_t arg0, parg_t arg1, parg_t arg2, parg_t arg3)
        __attribute__ ((noinline)) {

    pcode |= PANIC_WARN_FLAG;

    _p = pcode; _w = where;
    _a0 = arg0; _a1 = arg1;
    _a2 = arg2; _a3 = arg3;

//    MAYBE_SAVE_SR_AND_DINT;
    debug_break(0);
  }


  /*
   * Panic.panic: something really bad happened.
   * Simple version.   Do nothing allow debug break.
   */

  async command void Panic.panic(uint8_t pcode, uint8_t where,
        parg_t arg0, parg_t arg1, parg_t arg2, parg_t arg3)
        __attribute__ ((noinline)) {
    _p = pcode; _w = where;
    _a0 = arg0; _a1 = arg1;
    _a2 = arg2; _a3 = arg3;
    debug_break(1);
    if (!m_in_panic) {
      /*
       * Panic.hook may call code that may cause a panic.  Don't loop
       */
      m_in_panic = TRUE;
      signal Panic.hook();
    } else
      m_in_panic |= 0x80;               /* flag a double */
    debug_break(2);
  }


  command error_t Init.init() {
    save_sr_free = TRUE;
    save_sr = 0xffff;
    return SUCCESS;
  }


  default async event void Panic.hook() { }
}
