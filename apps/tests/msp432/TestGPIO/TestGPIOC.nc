/*
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 */

/*
 * @author: Eric B. Decker <cire831@gmail.com>
 */

norace uint32_t Fire0_count;
 
module TestGPIOC {
  uses {
    interface Leds;
    interface Boot;
    interface HplMsp432Gpio as Pin0;
    interface HplMsp432Gpio as Pin1;
    interface HplMsp432Gpio as Pin2;
    interface HplMsp432PortInt as Pin0Int;
  }
}
implementation {
  uint8_t state;

  void wack_pin0() {
    call Pin0.setFunction(MSP432_GPIO_BASIC);
    state = call Pin0.getFunction();

    call Pin0.setResistorMode(MSP432_GPIO_RESISTOR_OFF);
    state = call Pin0.getResistorMode();

    call Pin0.setResistorMode(MSP432_GPIO_RESISTOR_PULLUP);
    state = call Pin0.getResistorMode();

    call Pin0.makeOutput();
    call Pin0.clr();
    state = call Pin0.get();
    call Pin0.set();
    state = call Pin0Int.getValue();
    call Pin0Int.edgeRising();
    call Pin0Int.clear();
    Fire0_count = 0;
    call Pin0Int.enable();
  }


  void wack_pin1() {
    call Pin1.setFunction(MSP432_GPIO_BASIC);
    state = call Pin1.getFunction();

    call Pin1.setResistorMode(MSP432_GPIO_RESISTOR_OFF);
    state = call Pin1.getResistorMode();

    call Pin1.setResistorMode(MSP432_GPIO_RESISTOR_PULLUP);
    state = call Pin1.getResistorMode();

    call Pin1.makeOutput();
    call Pin1.clr();
    state = call Pin1.get();
    call Pin1.set();
    state = call Pin1.get();
    call Pin1.makeInput();
#ifdef notdef
    state = call Pin1Int.getValue();
    call Pin1Int.edgeRising();
    call Pin1Int.clear();
    call Pin1Int.enable();
#endif
  }

  void wack_pin2() {
    call Pin2.setFunction(MSP432_GPIO_BASIC);
    state = call Pin2.getFunction();

    call Pin2.setResistorMode(MSP432_GPIO_RESISTOR_OFF);
    state = call Pin2.getResistorMode();

    call Pin2.setResistorMode(MSP432_GPIO_RESISTOR_PULLUP);
    state = call Pin2.getResistorMode();

    call Pin2.makeOutput();
    call Pin2.clr();
    state = call Pin2.get();
    call Pin2.set();
    state = call Pin2.get();
    call Pin2.makeInput();
#ifdef notdef
    state = call Pin2Int.getValue();
    call Pin2Int.edgeRising();
    call Pin2Int.clear();
    call Pin2Int.enable();
#endif
  }


  event void Boot.booted() {
    wack_pin0();
    wack_pin1();
    wack_pin2();
  }

  
  async event void Pin0Int.fired() {
    Fire0_count++;
    call Pin0.toggle();
//    call Leds.led0Toggle();
//    __bkpt(0x55);
    __nop();
  }
  
#ifdef notdef
  async event void Pin1Int.fired() {
    __bkpt(0x56);
    __nop();
  }
  
  async event void Pin2Int.fired() {
    __bkpt(0x57);
    __nop();
  }
#endif
}
