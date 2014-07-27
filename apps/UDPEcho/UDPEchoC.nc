/*
 * Copyright (c) 2008 The Regents of the University  of California.
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

#include <lib6lowpan/6lowpan.h>

configuration UDPEchoC {

} implementation {
  components MainC, LedsC;
  components UDPEchoP;

  UDPEchoP.Boot -> MainC;
  UDPEchoP.Leds -> LedsC;

  components new TimerMilliC();
  components IPStackC;

  UDPEchoP.RadioControl ->  IPStackC;
  components new UdpSocketC() as Echo,
    new UdpSocketC() as Status;
  UDPEchoP.Echo -> Echo;

  UDPEchoP.Status -> Status;

  UDPEchoP.StatusTimer -> TimerMilliC;

  components UdpC, IPDispatchC;
  UDPEchoP.IPStats -> IPDispatchC;
  UDPEchoP.UDPStats -> UdpC;

#ifdef RPL_ROUTING
  components RPLRoutingC;
#endif

  components RandomC;
  UDPEchoP.Random -> RandomC;

  // UDP shell on port 2000
  components UDPShellC;

  // prints the routing table
  components RouteCmdC;
#ifdef IN6_PREFIX
  components StaticIPAddressTosIdC; // Use TOS_NODE_ID in address
  //components StaticIPAddressC; // Use LocalIeee154 in address
#else
  components Dhcp6C;
#endif

#ifdef PRINTFUART_ENABLED
  /* This component wires printf directly to the serial port, and does
   * not use any framing.  You can view the output simply by tailing
   * the serial device.  Unlike the old printfUART, this allows us to
   * use PlatformSerialC to provide the serial driver.
   *
   * For instance:
   * $ stty -F /dev/ttyUSB0 115200
   * $ tail -f /dev/ttyUSB0
  */
  components SerialPrintfC;

  /* This is the alternative printf implementation which puts the
   * output in framed tinyos serial messages.  This lets you operate
   * alongside other users of the tinyos serial stack.
   */
  // components PrintfC;
  // components SerialStartC;
#endif

}
