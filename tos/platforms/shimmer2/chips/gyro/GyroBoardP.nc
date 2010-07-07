/*
 * Copyright (c) 2009, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author  Steve Ayer
 * @date    August, 2009
 *
 * tinyos-2.x port
 * @date    March, 2010
 * 
 */

#include <UserButton.h>

module GyroBoardP {
  provides {
    interface Init;
    interface StdControl;
    interface GyroBoard;
  }
  uses{
    interface Notify<button_state_t> as buttonNotify;
  }
}

implementation {
  command error_t Init.init(){
    register uint16_t i;

    // power, active low
    TOSH_MAKE_PROG_OUT_OUTPUT();   
    TOSH_SEL_PROG_OUT_IOFUNC();
    TOSH_SET_PROG_OUT_PIN();    // off

    // analog signal enable, active low
    TOSH_MAKE_SER0_CTS_OUTPUT();
    TOSH_SEL_SER0_CTS_IOFUNC();
    TOSH_SET_SER0_CTS_PIN();    // signal disabled

    // signal goes to gyro-zero pins
    TOSH_MAKE_UTXD0_OUTPUT();
    TOSH_SEL_UTXD0_IOFUNC();
    TOSH_CLR_UTXD0_PIN();

    // this one tied to the led
    TOSH_MAKE_URXD0_OUTPUT();
    TOSH_SEL_URXD0_IOFUNC();
    call GyroBoard.ledOff();

    // x
    TOSH_MAKE_ADC_1_INPUT();         
    TOSH_SEL_ADC_1_MODFUNC();

    // y
    TOSH_MAKE_ADC_6_INPUT();         
    TOSH_SEL_ADC_6_MODFUNC();

    // z
    TOSH_MAKE_ADC_2_INPUT();         
    TOSH_SEL_ADC_2_MODFUNC();

    /*
     * gyro power-down after start-up transients, which are particularly rough during programming
     * we're waiting for caps to discharge...
     */
    for(i = 0; i < 6000; i++)
      TOSH_uwait(1000);

    // now power it up, max ready-time 200ms
    TOSH_CLR_PROG_OUT_PIN();

    for(i = 0; i < 200; i++)
      TOSH_uwait(1000);

    call buttonNotify.enable();
 
    return SUCCESS;
  }

  command error_t StdControl.start(){
    call buttonNotify.enable();
    /*
     * adding a redundant power-up for apps that power cycle the gyro mid-course to save current
     * since we're past the initial on-dock programming, gyro should power back up gracefully
     */
    TOSH_CLR_PROG_OUT_PIN();     

    // enable analog signal path
    TOSH_CLR_SER0_CTS_PIN();     

    return SUCCESS;
  }

  command error_t StdControl.stop(){
    // disable analog signals, then power down
    TOSH_SET_SER0_CTS_PIN();   
    TOSH_SET_PROG_OUT_PIN();

    // kill the led
    call GyroBoard.ledOff();
    call buttonNotify.disable();

    return SUCCESS;
  }

  command void GyroBoard.autoZero() {
    TOSH_SET_UTXD0_PIN();
    
    TOSH_uwait(100);  // pulse between 2 (!) and 1500 usec
    
    TOSH_CLR_UTXD0_PIN();

    TOSH_uwait(6900);  // takes 7ms to settle
  }

  command void GyroBoard.ledOn() {
    TOSH_CLR_URXD0_PIN();
  }

  command void GyroBoard.ledOff() {
    TOSH_SET_URXD0_PIN();
  }

  command void GyroBoard.ledToggle() {
    TOSH_TOGGLE_URXD0_PIN();
  }

  event void buttonNotify.notify( button_state_t val){
    signal GyroBoard.buttonPressed();
  }
}




