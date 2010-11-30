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

#include "dhcp6.h"

module Dhcp6P {
  provides interface StdControl;
  uses {
    interface UDP;
    interface Timer<TMilli>;
    interface Random;
  }
} implementation {
  int m_state;
  uint32_t m_txid;
  
  command error_t StdControl.start() {
    m_state = DH6_SOLICIT;
    m_txid = call Random.rand32();
    call UDP.bind(DH6PORT_DOWNSTREAM);
  }

  command error_t StdControl.stop() { }

  void sendSolicit() {
    struct dh6_solicit sol;
    sol.dh6_hdr.dh6_type_txid = htonl((DHCP_SOLICIT << 16) | m_txid);
    sol.dh6_id.type = htons(DH6OPT_CLIENTID);
    sol.dh6_id.len = htons(8);
    sol.dh6_id.duid_ll.duid_type = 3;
    sol.dh6_id.duid_ll.hw_type = HWTYPE_EUI64;
    
  }

  event void Timer.fired() {
    switch (m_state) {
    case DH6_SOLICIT:
      sendSolicit();
      break;
    }
  }
}
