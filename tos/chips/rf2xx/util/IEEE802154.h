/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2009-04-04 00:43:55 $
 */

#ifndef __IEEE802154_H__
#define __IEEE802154_H__

/*
 * Define an address representation.
 * Only short addresses are currently used in this stack.
 */
typedef uint16_t ieee154_panid_t;
typedef uint16_t ieee154_saddr_t;

enum {
  IEEE154_BROADCAST_ADDR = 0xffff,
};

#if 0
// some ideas of how to represent long addresses
typedef enum {
  IEEE154_SHORT_ADDR,
  IEEE154_LONG_ADDR,
} ieee154_atype_t;

typedef union {
  uint8_t  u_addr[8];
  uint16_t u_addr16[4];
  uint32_t u_addr32[2];
} ieee154_laddr_t;

typedef struct {
  ieee154_atype_t type;
  union {
    ieee154_saddr_t s_addr;
    ieee154_laddr_t l_addr;
  } addr;
#define addr    addr.l_addr.u_addr
#define addr16  addr.l_addr.u_addr16
#define addr32  addr.l_addr.u_addr32
} ieee154_addr_t;
#endif

#endif
