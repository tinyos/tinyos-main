// $Id: LedsC.nc,v 1.1 2007-07-11 00:42:56 razvanm Exp $

/*									tab:2
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

module LedsC {
  provides interface Leds;
}

implementation {

  enum {
    RED_BIT = 1,
    GREEN_BIT = 2,
    YELLOW_BIT = 4
  };

  command void Leds.set(uint8_t ledsOn) {
    if (ledsOn & GREEN_BIT) 
      TOSH_CLR_GREEN_LED_PIN();
    else
      TOSH_SET_GREEN_LED_PIN();
    if (ledsOn & YELLOW_BIT ) 
      TOSH_CLR_YELLOW_LED_PIN();
    else 
      TOSH_SET_YELLOW_LED_PIN();
    if (ledsOn & RED_BIT) 
      TOSH_CLR_RED_LED_PIN();
    else 
      TOSH_SET_RED_LED_PIN();
  }

  command void Leds.flash(uint8_t a) {
    uint8_t i, j;
    for ( i = 3; i; i-- ) {
      call Leds.set(a);
      for ( j = 4; j; j-- )
	wait(0xffff);
      call Leds.set(0);
      for ( j = 4; j; j-- )
	wait(0xffff);
    }
  }

  command void Leds.glow(uint8_t a, uint8_t b) {
    int i;
    for (i = 1536; i > 0; i -= 4) {
      call Leds.set(a);
      wait(i);
      call Leds.set(b);
      wait(1536-i);
    }
  }

}
