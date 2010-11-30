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
 * DHCP v6 Client implementation for TinyOS
 *
 * Implements a simple subset of RFC3315 DHCP for stateful address
 * configuration.  This protocol engine solicits on-link DHCP servers
 * or relay agents, and then attempts to obtain permanent (IA_NA)
 * addresses from them.  After an address is acquired, it will renew
 * it using the parameters contained in the Identity Association
 * binding; if the lease expires, it will revoke the address using the
 * IPAddress interface.  At that point all components should stop
 * using that address as it is no longer valid.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */
configuration Dhcp6ClientC {
  provides interface Dhcp6Info;
} implementation {
  components Dhcp6ClientP;
  components IPStackControlP;
  components new UdpSocketC();
  components new TimerMilliC();
  components RandomC, Ieee154AddressC, IPAddressC;

  Dhcp6Info = Dhcp6ClientP;

  IPStackControlP.StdControl -> Dhcp6ClientP;
  
  Dhcp6ClientP.UDP -> UdpSocketC;
  Dhcp6ClientP.Timer -> TimerMilliC;
  Dhcp6ClientP.Ieee154Address -> Ieee154AddressC;
  Dhcp6ClientP.IPAddress -> IPAddressC;
  Dhcp6ClientP.Random -> RandomC;

  components LedsC;
  Dhcp6ClientP.Leds -> LedsC;
}
