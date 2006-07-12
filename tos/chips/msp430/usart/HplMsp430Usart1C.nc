/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * @author Joe Polastre
 */

#include "msp430UsartResource.h"

configuration HplMsp430Usart1C {
  provides interface Init;
  provides interface HplMsp430Usart;
  provides interface HplMsp430UsartInterrupts;
  provides interface Resource[ uint8_t id ];
  provides interface ResourceController;
  provides interface ArbiterInfo;
}

implementation {

  components HplMsp430Usart1P as HplUsartP;
  components HplMsp430GeneralIOC as GIO;
  components new FcfsArbiterC(MSP430_HPLUSART1_RESOURCE) as Arbiter;

  HplMsp430Usart = HplUsartP;
  HplMsp430UsartInterrupts = HplUsartP;

  Init = Arbiter;
  Resource = Arbiter;
  ResourceController = Arbiter;
  ArbiterInfo = Arbiter;

  HplUsartP.SIMO -> GIO.SIMO1;
  HplUsartP.SOMI -> GIO.SOMI1;
  HplUsartP.UCLK -> GIO.UCLK1;
  HplUsartP.URXD -> GIO.URXD1;
  HplUsartP.UTXD -> GIO.UTXD1;

}
