
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
 * @author Joe Polastre
 */
configuration HplMsp430InterruptC
{
#ifdef __msp430_have_port1
  provides interface HplMsp430Interrupt as Port10;
  provides interface HplMsp430Interrupt as Port11;
  provides interface HplMsp430Interrupt as Port12;
  provides interface HplMsp430Interrupt as Port13;
  provides interface HplMsp430Interrupt as Port14;
  provides interface HplMsp430Interrupt as Port15;
  provides interface HplMsp430Interrupt as Port16;
  provides interface HplMsp430Interrupt as Port17;
#endif
#ifdef __msp430_have_port2
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
#ifdef __msp430_have_port1
  Port10 = HplInterruptP.Port10;
  Port11 = HplInterruptP.Port11;
  Port12 = HplInterruptP.Port12;
  Port13 = HplInterruptP.Port13;
  Port14 = HplInterruptP.Port14;
  Port15 = HplInterruptP.Port15;
  Port16 = HplInterruptP.Port16;
  Port17 = HplInterruptP.Port17;
#endif
#ifdef __msp430_have_port2
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
