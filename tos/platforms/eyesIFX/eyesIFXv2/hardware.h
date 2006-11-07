/*
 * Copyright (c) 2004, Technische Universität Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universität Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: hardware.h,v 1.3 2006-11-07 19:31:23 scipio Exp $
 *
 */

#ifndef TOSH_HARDWARE_EYESIFXV2
#define TOSH_HARDWARE_EYESIFXV2

#include "msp430hardware.h"

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, 5, 0); // Compatibility with the mica2
TOSH_ASSIGN_PIN(GREEN_LED, 5, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, 5, 2);

TOSH_ASSIGN_PIN(LED0, 5, 0);
TOSH_ASSIGN_PIN(LED1, 5, 1);
TOSH_ASSIGN_PIN(LED2, 5, 2);
TOSH_ASSIGN_PIN(LED3, 5, 3);

// TDA5250 assignments
TOSH_ASSIGN_PIN(TDA_BUSM, 1, 5);  // TDA BUSM
TOSH_ASSIGN_PIN(TDA_ENTDA, 1, 6); // TDA EN_TDA
TOSH_ASSIGN_PIN(TDA_TXRX, 1, 4);  // TDA TX/RX
TOSH_ASSIGN_PIN(TDA_DATA, 1, 1);  // TDA DATA (timerA, CCI0A)
TOSH_ASSIGN_PIN(TDA_PWDDD, 1, 0); // TDA PWDDD

// USART0 assignments
TOSH_ASSIGN_PIN(SIMO0, 3, 1); // SIMO (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(SOMI0, 3, 2); // SOMI (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(UCLK0, 3, 3); // UCLK (MSP) -> BUSCLK (TDA5250)
TOSH_ASSIGN_PIN(UTXD0, 3, 4);   // USART0 -> data1 (TDA5250)
TOSH_ASSIGN_PIN(URXD0, 3, 5);   // USART0 -> data1 (TDA5250)

// USART1 assignments

TOSH_ASSIGN_PIN(UTXD1, 3, 6);   // USART1 -> USB
TOSH_ASSIGN_PIN(URXD1, 3, 7);   // USART1 -> USB
/*
void TOSH_SEL_SIMO1_IOFUNC() { }
void TOSH_SEL_SOMI1_IOFUNC() { }
void TOSH_SEL_UCLK1_IOFUNC() { }
void TOSH_SEL_SIMO1_MODFUNC() { }
void TOSH_SEL_SOMI1_MODFUNC() { }
void TOSH_SEL_UCLK1_MODFUNC() { }
*/
// Sensor assignments
TOSH_ASSIGN_PIN(RSSI, 6, 3);
TOSH_ASSIGN_PIN(TEMP, 6, 0);
TOSH_ASSIGN_PIN(LIGHT, 6, 2);
TOSH_ASSIGN_PIN(VREF, 6, 7);
TOSH_ASSIGN_PIN(B0, 6, 4);
TOSH_ASSIGN_PIN(B1, 6, 5);
TOSH_ASSIGN_PIN(B2, 6, 7);
TOSH_ASSIGN_PIN(B3, 6, 6);
TOSH_ASSIGN_PIN(B4, 6, 1);


// Potentiometer
TOSH_ASSIGN_PIN(POT_EN, 2, 4);
TOSH_ASSIGN_PIN(POT_SD, 2, 3);

// TimerA output
TOSH_ASSIGN_PIN(TIMERA0, 1, 1); //2,7
TOSH_ASSIGN_PIN(TIMERA1, 1, 2);
TOSH_ASSIGN_PIN(TIMERA2, 1, 3);

// TimerB output
TOSH_ASSIGN_PIN(TIMERB0, 4, 0);
TOSH_ASSIGN_PIN(TIMERB1, 4, 1);
TOSH_ASSIGN_PIN(TIMERB2, 4, 2);

// SMCLK output
TOSH_ASSIGN_PIN(SMCLK, 5, 5); //2,7

// ACLK output
TOSH_ASSIGN_PIN(ACLK, 2, 0);

// Flash
TOSH_ASSIGN_PIN(FLASH_CS, 1, 7);

TOSH_ASSIGN_PIN(DEBUG_1, 1, 1);
TOSH_ASSIGN_PIN(DEBUG_2, 1, 2);

// Temperature sensor enable
TOSH_ASSIGN_PIN(TEMP_EN, 5, 4);
 
// USB power monitoring
TOSH_ASSIGN_PIN(USB_POWER, 1, 3);

inline void uwait(uint16_t u) 
{ 
  uint16_t t0 = TAR;
  while((TAR - t0) <= u);
} 


#undef atomic
void TOSH_SET_PIN_DIRECTIONS(void)
{

  // Default seting is I/O and output zero.

atomic {

  P1OUT = 0x00;
  P2OUT = 0x00;
  P3OUT = 0x00;
  P4OUT = 0x00;
  P5OUT = 0x00;
  P6OUT = 0x00;

  P1SEL = 0x00;
  P2SEL = 0x00;
  P3SEL = 0x00;
  P4SEL = 0x00;
  P5SEL = 0x00;
  P6SEL = 0x00;
 
    P1DIR = 0x07;
//  P2DIR = 0xff;
//  P3DIR = 0xff;
    P4DIR = 0xff;
    P5DIR = 0x0f;
    P6DIR = 0xf0;

  TOSH_MAKE_TDA_PWDDD_OUTPUT();
  TOSH_MAKE_TDA_ENTDA_OUTPUT();
  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_MAKE_POT_SD_OUTPUT();
  TOSH_MAKE_POT_EN_OUTPUT();


  //disable temperature sensor
  TOSH_CLR_TEMP_EN_PIN();
  TOSH_MAKE_TEMP_EN_OUTPUT();

  // detect USB power
  TOSH_SEL_USB_POWER_MODFUNC();
  TOSH_MAKE_USB_POWER_INPUT();
  
  
 // wait 12ms for the radio to start
  uwait(1024*12);

  TOSH_SET_TDA_ENTDA_PIN(); // deselect the radio
  TOSH_SET_FLASH_CS_PIN(); // put flash in standby mode
  TOSH_SET_POT_SD_PIN(); // put potentiometer in shutdown mode
  TOSH_SET_POT_EN_PIN(); // deselect potentiometer
  TOSH_SEL_TEMP_MODFUNC(); //prepare pin for analog excitation from the temperature sensor
  TOSH_MAKE_TEMP_INPUT();
  TOSH_SEL_LIGHT_MODFUNC(); //prepare pin for analog excitation from the light sensor
  TOSH_MAKE_LIGHT_INPUT();

  P1IE = 0;
  P2IE = 0;

  TOSH_SET_TDA_PWDDD_PIN(); // put radio in sleep
}
}
#endif //TOSH_HARDWARE_EYESIFXV2
