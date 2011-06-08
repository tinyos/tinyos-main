/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

#include <lib6lowpan/6lowpan.h>

configuration BinaryShellC {
  provides interface BinaryCommand[uint16_t];

} implementation {

  components new UdpSocketC();
  components BinaryShellP, LedsC;

  BinaryCommand = BinaryShellP;

  BinaryShellP.UDP -> UdpSocketC;

  components ICMPPingC;
  BinaryShellP.ICMPPing -> ICMPPingC.ICMPPing[unique("PING")];

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
  components CounterMilli32C;
  BinaryShellP.Uptime -> CounterMilli32C;
#endif

  components MainC;
  BinaryShellP.Boot -> MainC;

  BinaryShellP.CmdEcho -> BinaryShellP.BinaryCommand[BSHELL_ECHO];
  BinaryShellP.CmdPing6 -> BinaryShellP.BinaryCommand[BSHELL_PING6];
  BinaryShellP.CmdIdent -> BinaryShellP.BinaryCommand[BSHELL_IDENT];
  BinaryShellP.CmdUptime -> BinaryShellP.BinaryCommand[BSHELL_UPTIME];

}
