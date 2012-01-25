// $Id: HplAt45dbIOC.nc,v 1.2 2010-06-29 22:07:53 scipio Exp $
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
