// $Id: HplAt45dbIOC.nc,v 1.1 2008-01-24 20:45:51 sallai Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */


/**
 * Low-level access functions for the AT45DB flash on the mica2 and micaz.
 *
 * @author David Gay
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

configuration HplAt45dbIOC {
  provides {
    interface Resource;
    interface SpiByte as FlashSpi;
    interface HplAt45dbByte;
  }
}
implementation {
  // Wire up byte I/O to At45db
  components HplAt45dbIOP, HplAtm128GeneralIOC as Pins, PlatformC;
  components BusyWaitMicroC;
  components new NoArbiterC();

  Resource = NoArbiterC;
  FlashSpi = HplAt45dbIOP;
  HplAt45dbByte = HplAt45dbIOP;

  PlatformC.SubInit -> HplAt45dbIOP;
  HplAt45dbIOP.Select -> Pins.PortA3;
  HplAt45dbIOP.Clk -> Pins.PortD5;
  HplAt45dbIOP.In -> Pins.PortD2;
  HplAt45dbIOP.Out -> Pins.PortD3;
  HplAt45dbIOP.BusyWait -> BusyWaitMicroC;
}
