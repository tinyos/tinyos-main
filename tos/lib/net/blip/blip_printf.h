#ifndef BLIP_PRINTF_H
#define BLIP_PRINTF_H
/*
 * Conditionally include printf functionality in an app.
 *
 * In the future we may allow more fine-grained control over weather
 * printf is enabled
 */

#ifdef PRINTFUART_ENABLED
#include "printf.h"
#else
#define printf(fmt, args ...) ;
#define printfflush() ;

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

#endif

#define printf_in6addr(a) ;
#define printf_buf(buf, len) ;



#endif
