// $Id: PowerOffM.nc,v 1.2 2008-06-11 00:46:26 razvanm Exp $

/*
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module PowerOffM {
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
    for ( i = 0; i < 4; i++ )
      wait(0xffff);

    // if user button is pressed, power down
    if (!TOSH_READ_USERINT_PIN())
      haltsystem();

    return SUCCESS;

  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }

}
