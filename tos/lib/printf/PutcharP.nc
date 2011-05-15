/*
 * Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

 /*
 * Copyright (c) 2007 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This component provides a TinyOS-compatible bridge to the
 * system-specific mechanism of providing single-character output to
 * the environment's printf(3c) infrastructure.  Components that
 * provide a libc-based printf facility in TinyOS should implement the
 * Putchar interface and connect it to this module.
 *
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @author Peter A. Bigot <pabigot@users.sourceforge.net>
 */

#if defined (_H_msp430hardware_h) || defined (_H_atmega128hardware_H)
  #include <stdio.h>
#else
#ifdef __M16C60HARDWARE_H__ 
  #include "m16c60_printf.h"
#else
  #include "generic_printf.h"
#endif
#endif
#undef putchar

#ifdef _H_atmega128hardware_H
static int uart_putchar(char c, FILE *stream);
static FILE atm128_stdout = 
	FDEV_SETUP_STREAM(TCAST(int (*)(char c, FILE *stream), uart_putchar), 
	NULL, _FDEV_SETUP_WRITE);
#endif

module PutcharP {
  provides interface Init;
  uses interface Putchar;
} implementation {

  command error_t Init.init() {
      error_t rv = SUCCESS;
#ifdef _H_atmega128hardware_H
      stdout = &atm128_stdout;
#endif
      return rv;
  }

#ifdef _H_msp430hardware_h
  int putchar(int c) __attribute__((noinline)) @C() @spontaneous() {
#else
#ifdef _H_atmega128hardware_H
  int uart_putchar(char c, FILE *stream) __attribute__((noinline)) @C() @spontaneous() {
#else
#ifdef __M16C60HARDWARE_H__
  int lowlevel_putc(int c) __attribute__((noinline)) @C() @spontaneous() {
#else
  int lowlevel_putc(int c) __attribute__((noinline)) @C() @spontaneous() {
#endif
#endif
#endif
    return call Putchar.putchar (c);
  }
}
