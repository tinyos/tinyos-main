// $Id: PowerOffC.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $

/*
 *
 *
 * Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module PowerOffC {
  provides {
    interface Init;
    interface StdControl;
  }
  uses {
    interface Leds;
    interface StdControl as SubControl;
  }
}

implementation {

  void haltsystem() {

    uint16_t _lpmreg;

    TOSH_SET_PIN_DIRECTIONS();

    call SubControl.stop();

    call Leds.glow(0x7, 0x0);

    _lpmreg = LPM4_bits;
    _lpmreg |= SR_GIE;

    __asm__ __volatile__( "bis  %0, r2" : : "m" ((uint16_t)_lpmreg) );

  }

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t StdControl.start() {

    int i;

    // wait a short period for things to stabilize
    for ( i = 0; i < 4; i++ ) {
      wait(0xffff);
		}

		// TinyNode: we don't have a user button

    // if user button is pressed, power down
    //if (!TOSH_READ_USERINT_PIN()) {
		//haltsystem(); 
		//}

    return SUCCESS;

  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }

}
