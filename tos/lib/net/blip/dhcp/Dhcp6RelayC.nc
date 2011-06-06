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
 * DHCP v6 relay agent for TinyOS
 *
 * DHCP allows relay agents to forward traffic to an external DHCP
 * server which is not on-link with the requesting client.  To do
 * this, the relay agent reencapsulates the request message and
 * includes its own address and the address of the peer, before
 * sending the request on to the DCHP servers multicast group.  In
 * blip, this group is routed to the edge of the network where the
 * dhcp server is presumably running.
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

configuration Dhcp6RelayC {

} implementation {
  components Dhcp6RelayP, Dhcp6ClientC;
  components IPAddressC, Ieee154AddressC;
  components new TimerMilliC(), new UdpSocketC();
  components RandomC;
  components MainC;

  Dhcp6RelayP.UDP -> UdpSocketC;
  Dhcp6RelayP.IPAddress -> IPAddressC;
  Dhcp6RelayP.Ieee154Address -> Ieee154AddressC;
  Dhcp6RelayP.Random -> RandomC;
  Dhcp6RelayP.Boot -> MainC;
  Dhcp6RelayP.AdvTimer -> TimerMilliC;
  Dhcp6RelayP.Dhcp6Info -> Dhcp6ClientC;

}
