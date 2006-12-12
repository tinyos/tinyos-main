// $Id: HplAt45dbIOP.nc,v 1.4 2006-12-12 18:23:43 vlahan Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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
    interface HplAtm128Interrupt as InInterrupt;
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

    call InInterrupt.disable();
    call InInterrupt.edge(TRUE);

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
	 "\tsbi 18,3\n" \
	 "\tsbi 18,5\n" \
	 "\tsbic 16,2\n" \
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
    // Setup interrupt on rising edge of flash in
    atomic
      {
	call InInterrupt.clear();
	call InInterrupt.enable();
	call Clk.clr();
	// We need to wait at least 2 cycles here (because of the signal
	// acquisition delay). It's also good to wait a few microseconds
	// to get the fast ("FAIL") exit from wait (reads are twice as fast
	// with a 2us delay...)
	call BusyWait.wait(2);

	if (call In.get())
	  signal InInterrupt.fired(); // already high
      }
  }

  async event void InInterrupt.fired() {
    call InInterrupt.disable();
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
