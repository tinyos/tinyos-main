/*
 * Copyright (c) 2008-2010 The Regents of the University  of California.
 * All rights reserved."
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
 *
 */
/**
 * Component for doing compile-time address allocation. Wired by the
 * stack, sets a static address based on IN6_PREFIX and the EUI64 on
 * boot. Useful for development or of you want to hard-code addresses.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 * @author Brad Campbell <bradjc@umich.edu>
 */
#include <lib6lowpan/ip.h>

module StaticIPAddressP {
  uses {
    interface Boot;
    interface IPAddress;
    interface LocalIeeeEui64;
  }
} implementation {

  event void Boot.booted() {
    struct in6_addr addr;
    ieee154_laddr_t ext;

    call IPAddress.getLLAddr(&addr);

    inet_pton6(IN6_PREFIX, &addr);

    // Set the lower 64 bits as the link-local 64 bits
    ext = call LocalIeeeEui64.getId();
    memcpy(addr.s6_addr+8, ext.data, 8);
    addr.s6_addr[8] ^= 0x2;

    call IPAddress.setAddress(&addr);
  }

  event void IPAddress.changed(bool valid) {}
}
