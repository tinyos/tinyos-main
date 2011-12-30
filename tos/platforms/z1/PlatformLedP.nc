/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

/** Defines the Led and MultiLed interfaces in terms of the underlying
 * LedsC component.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
module PlatformLedP {
  provides {
    interface MultiLed;
    interface Led[uint8_t led_id];
  }
  uses {
    interface Leds;
  }
} implementation {

  async command void Led.on[ uint8_t led_id ] ()
  {
    switch(led_id) {
      case 0: call Leds.led0On(); break;
      case 1: call Leds.led1On(); break;
      case 2: call Leds.led2On(); break;
    }
  }

  async command void Led.off[ uint8_t led_id ] ()
  {
    switch(led_id) {
      case 0: call Leds.led0Off(); break;
      case 1: call Leds.led1Off(); break;
      case 2: call Leds.led2Off(); break;
    }
  }

  async command void Led.set[ uint8_t led_id ] (bool turn_on)
  {
    if (turn_on) {
      call Led.on[led_id]();
    } else {
      call Led.off[led_id]();
    }
  }

  async command void Led.toggle[ uint8_t led_id ] ()
  {
    switch(led_id) {
      case 0: call Leds.led0Toggle(); break;
      case 1: call Leds.led1Toggle(); break;
      case 2: call Leds.led2Toggle(); break;
    }
  }

  async command unsigned int MultiLed.get () { return call Leds.get(); }

  async command void MultiLed.set (unsigned int val) { call Leds.set(val); }

  async command void MultiLed.on (unsigned int led_id) { call Led.on[led_id](); }

  async command void MultiLed.off (unsigned int led_id) { call Led.off[led_id](); }

  async command void MultiLed.setSingle (unsigned int led_id, bool turn_on) { call Led.set[led_id](turn_on); }

  async command void MultiLed.toggle (unsigned int led_id) { call Led.toggle[led_id](); }

}
