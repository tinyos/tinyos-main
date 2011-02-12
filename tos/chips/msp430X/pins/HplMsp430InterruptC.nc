/**
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * - Neither the name of the DEXMA SENSORS SL nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * DEXMA SENSORS SL OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * HPL for the TI MSP430 family of microprocessors. This provides an
 * abstraction for GPIO interrupts.
 *
 * Added support for msp430X family
 * @author Joe Polastre
 * @author Xavier Orduna <xorduna@dexmatech.com>
 */
configuration HplMsp430InterruptC
{
#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1_R__)
  provides interface HplMsp430Interrupt as Port10;
  provides interface HplMsp430Interrupt as Port11;
  provides interface HplMsp430Interrupt as Port12;
  provides interface HplMsp430Interrupt as Port13;
  provides interface HplMsp430Interrupt as Port14;
  provides interface HplMsp430Interrupt as Port15;
  provides interface HplMsp430Interrupt as Port16;
  provides interface HplMsp430Interrupt as Port17;
#endif
#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2_R__)
  provides interface HplMsp430Interrupt as Port20;
  provides interface HplMsp430Interrupt as Port21;
  provides interface HplMsp430Interrupt as Port22;
  provides interface HplMsp430Interrupt as Port23;
  provides interface HplMsp430Interrupt as Port24;
  provides interface HplMsp430Interrupt as Port25;
  provides interface HplMsp430Interrupt as Port26;
  provides interface HplMsp430Interrupt as Port27;
#endif
}
implementation
{
  components HplMsp430InterruptP as HplInterruptP;
#if defined(__msp430_have_port1) || defined(__MSP430_HAS_PORT1_R__)
  Port10 = HplInterruptP.Port10;
  Port11 = HplInterruptP.Port11;
  Port12 = HplInterruptP.Port12;
  Port13 = HplInterruptP.Port13;
  Port14 = HplInterruptP.Port14;
  Port15 = HplInterruptP.Port15;
  Port16 = HplInterruptP.Port16;
  Port17 = HplInterruptP.Port17;
#endif
#if defined(__msp430_have_port2) || defined(__MSP430_HAS_PORT2_R__)
  Port20 = HplInterruptP.Port20;
  Port21 = HplInterruptP.Port21;
  Port22 = HplInterruptP.Port22;
  Port23 = HplInterruptP.Port23;
  Port24 = HplInterruptP.Port24;
  Port25 = HplInterruptP.Port25;
  Port26 = HplInterruptP.Port26;
  Port27 = HplInterruptP.Port27;
#endif
}
