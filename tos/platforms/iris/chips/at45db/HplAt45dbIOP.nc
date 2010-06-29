// $Id: HplAt45dbIOP.nc,v 1.3 2010-06-29 22:07:53 scipio Exp $

/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * Copyright (c) 2002-2003 Intel Corporation
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
 * Low level hardware access to the onboard AT45DB flash chip.
 * <p>
 * Note: This component includes optimised bit-banging SPI code with the
 * pins hardwired.  Don't copy it to some other platform without
 * understanding it (see txByte).
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

#include "Timer.h"

module HplAt45dbIOP {
  provides {
    interface Init;
    interface SpiByte as FlashSpi;
    interface HplAt45dbByte;
  }
  uses {
    interface GeneralIO as Select;
    interface GeneralIO as Clk;
    interface GeneralIO as Out;
    interface GeneralIO as In;
    interface BusyWait<TMicro, uint16_t>;
  }
}
implementation
{
  // We use SPI mode 0 (clock low at select time)

  command error_t Init.init() {
    call Select.makeOutput();
    call Select.set();
    call Clk.clr();
    call Clk.makeOutput();
    call Out.set();
    call Out.makeOutput();
    call In.clr();
    call In.makeInput();
    return SUCCESS;
  }

  command void HplAt45dbByte.select() {
    call Clk.clr(); // ensure SPI mode 0
    call Select.clr();
  }

  command void HplAt45dbByte.deselect() {
    call Select.set();
  }

#define BITINIT \
  uint8_t clrClkAndData = PORTD & ~0x28

#define BIT(n) \
	PORTD = clrClkAndData; \
	asm __volatile__ \
        (  "sbrc %2," #n "\n" \
	 "\tsbi 11,3\n" \
	 "\tsbi 11,5\n" \
	 "\tsbic 9,2\n" \
	 "\tori %0,1<<" #n "\n" \
	 : "=d" (spiIn) : "0" (spiIn), "r" (spiOut))

  async command uint8_t FlashSpi.write(uint8_t spiOut) {
    uint8_t spiIn = 0;

    // This atomic ensures integrity at the hardware level...
    atomic
      {
	BITINIT;

	BIT(7);
	BIT(6);
	BIT(5);
	BIT(4);
	BIT(3);
	BIT(2);
	BIT(1);
	BIT(0);
      }

    return spiIn;
  }

  task void avail() {
    signal HplAt45dbByte.idle();
  }

  command void HplAt45dbByte.waitIdle() {
    // at45db041 rev d fix by handsomezhu hongsong at ios.cn
    // http://mail.millennium.berkeley.edu/pipermail/tinyos-help/2008-January/030255.html
    int i;
    call Clk.clr();
    call BusyWait.wait(2);
    while( ! call In.get() ) {
      for( i=0; i < 8; i ++ ) {
        call Clk.set();
        call Clk.clr();
        call BusyWait.wait(2);
      }
    }
    post avail();
  }

  command bool HplAt45dbByte.getCompareStatus() {
    call Clk.set();
    call Clk.clr();
    // Wait for compare value to propagate
    asm volatile("nop");
    asm volatile("nop");
    return !call In.get();
  }
}
