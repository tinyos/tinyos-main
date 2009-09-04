// $Id: NoLedsC.nc,v 1.1 2009-09-04 18:27:46 ayer1 Exp $

/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * A null operation replacement for the LedsC component. As many
 * components might concurrently signal information through LEDs,
 * using LedsC and NoLedsC allows an application builder to select
 * which components control the LEDs.
 *
 * @author Philip Levis
 * @date   March 19, 2005
 *
 */

module NoLedsC {
  provides interface Init;
  provides interface Leds;
}
implementation {

  command error_t Init.init() {return SUCCESS;}

  async command void Leds.led0On() {}
  async command void Leds.led0Off() {}
  async command void Leds.led0Toggle() {}

  async command void Leds.led1On() {}
  async command void Leds.led1Off() {}
  async command void Leds.led1Toggle() {}

  async command void Leds.led2On() {}
  async command void Leds.led2Off() {}
  async command void Leds.led2Toggle() {}

  async command uint8_t Leds.get() {return 0;}
  async command void Leds.set(uint8_t val) {}
}
