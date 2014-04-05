#ifndef BLIP_PRINTF_H
#define BLIP_PRINTF_H
/*
 * Conditionally include printf functionality in an app.
 *
 * In the future we may allow more fine-grained control over weather
 * printf is enabled.
 *
 * Also include utility functions for dumping several blip structures.
 */

#ifdef PRINTFUART_ENABLED
#include "printf.h"
#include <lib6lowpan/iovec.h>
#include <lib6lowpan/ip.h>

void printf_buf(uint8_t *buf, int len) {
  int i;
  for (i = 0; i < len; i++) {
    printf("%02x ", buf[i]);
  }
  printf("\n");
}

/* printf a whole iovec */
void iov_print(struct ip_iovec *iov) {
  struct ip_iovec *cur = iov;
  while (cur != NULL) {
    int i;
    printf("iovec (%p, %i) ", cur, cur->iov_len);
    for (i = 0; i < cur->iov_len; i++) {
      printf("%02x ", (uint8_t)cur->iov_base[i]);
    }
    printf("\n");
    cur = cur->iov_next;
  }
}

/* printf an internet address */
void printf_in6addr(struct in6_addr *a) {
  static char print_buf[64];
  inet_ntop6(a, print_buf, 64);
  printf("%s", print_buf);
}

int printf_ieee154addr(ieee154_addr_t *in) {
  int i;
  switch (in->ieee_mode) {
  case IEEE154_ADDR_SHORT:
    printf("IEEE154_ADDR_SHORT: 0x%x", in->i_saddr);
    break;
  case IEEE154_ADDR_EXT:
    printf("IEEE154_ADDR_EXT: ");

    for (i = 7; i >= 0; i--) {
      printf("%02x", in->i_laddr.data[i]);
      if (i > 0)
        printf(":");
    }
    break;
  }
  return 0;
}


#else  /* PRINTFUART_ENABLED */
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

/* disable all printfs by removing them in the preprocessor */
#define printf(fmt, args ...) ;
#define printfflush() ;
#define printf_in6addr(a) ;
#define printf_buf(buf, len) ;
#define iov_print(iov) ;
#define printf_ieee154addr(in) ;

#endif /* PRINTFUART_ENABLED */

#endif
