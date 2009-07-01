/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 * $Id: hardware.h,v 1.5 2009-07-01 19:26:59 scipio Exp $
 *
 */

#ifndef TOSH_HARDWARE_EYESIFX
#define TOSH_HARDWARE_EYESIFX

#include "msp430hardware.h"

// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, 5, 0); // Compatibility with the mica2
TOSH_ASSIGN_PIN(GREEN_LED, 5, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, 5, 2);

// Debug Pin assignments
TOSH_ASSIGN_PIN(DEBUG_PIN1, 1, 2);
TOSH_ASSIGN_PIN(DEBUG_PIN2, 1, 3);

TOSH_ASSIGN_PIN(LED0, 5, 0);
TOSH_ASSIGN_PIN(LED1, 5, 1);
TOSH_ASSIGN_PIN(LED2, 5, 2);
TOSH_ASSIGN_PIN(LED3, 5, 3);

// TDA5250 assignments
TOSH_ASSIGN_PIN(TDA_PWDDD, 1, 0); // TDA PWDDD
TOSH_ASSIGN_PIN(TDA_DATA, 1, 1);  // TDA DATA (timerA, CCI0A)
TOSH_ASSIGN_PIN(TDA_TXRX, 1, 4);  // TDA TX/RX
TOSH_ASSIGN_PIN(TDA_BUSM, 1, 5);  // TDA BUSM
TOSH_ASSIGN_PIN(TDA_ENTDA, 1, 6); // TDA EN_TDA

// USART0 assignments
TOSH_ASSIGN_PIN(SIMO0, 3, 1); // SIMO (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(SOMI0, 3, 2); // SOMI (MSP) -> BUSDATA (TDA5250)
TOSH_ASSIGN_PIN(UCLK0, 3, 3); // UCLK (MSP) -> BUSCLK (TDA5250)
TOSH_ASSIGN_PIN(UTXD0, 3, 4);   // USART0 -> data1 (TDA5250)
TOSH_ASSIGN_PIN(URXD0, 3, 5);   // USART0 -> data1 (TDA5250)

// USART1 assignments
TOSH_ASSIGN_PIN(UTXD1, 3, 6);   // USART1 -> ST3232
TOSH_ASSIGN_PIN(URXD1, 3, 7);   // USART1 -> ST3232
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

// Sensor assignments
TOSH_ASSIGN_PIN(RSSI, 6, 3);
TOSH_ASSIGN_PIN(TEMP, 6, 0);
TOSH_ASSIGN_PIN(LIGHT, 6, 2);
TOSH_ASSIGN_PIN(ADC_A1, 6, 1);

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

// send a bit via bit-banging to the flash
void TOSH_FLASH_M25P_DP_bit(bool set) {
  if (set)
    TOSH_SET_SIMO0_PIN();
  else
    TOSH_CLR_SIMO0_PIN();
  TOSH_SET_UCLK0_PIN();
  TOSH_CLR_UCLK0_PIN();
}

inline void TOSH_wait(void)
{
  nop(); nop();
}

inline void uwait(uint16_t u) 
{ 
  /*
  uint16_t i;
  if (u < 500)
    for (i=2; i < u; i++) { 
      asm volatile("nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   ::);
    }
  else
    for (i=0; i < u; i++) { 
      asm volatile("nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   "nop\n\t"
                   ::);
    }
  */
  uint16_t t0 = TAR;
  while((TAR - t0) <= u);
} 

void TOSH_FLASH_M25P_DP() {
  //  SIMO0, UCLK0
  TOSH_MAKE_SIMO0_OUTPUT();
  TOSH_MAKE_UCLK0_OUTPUT();
  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_SET_FLASH_CS_PIN();

  TOSH_wait();

  // initiate sequence;
  TOSH_CLR_FLASH_CS_PIN();
  TOSH_CLR_UCLK0_PIN();
  
  TOSH_FLASH_M25P_DP_bit(TRUE);   // 0
  TOSH_FLASH_M25P_DP_bit(FALSE);  // 1
  TOSH_FLASH_M25P_DP_bit(TRUE);   // 2
  TOSH_FLASH_M25P_DP_bit(TRUE);   // 3
  TOSH_FLASH_M25P_DP_bit(TRUE);   // 4
  TOSH_FLASH_M25P_DP_bit(FALSE);  // 5
  TOSH_FLASH_M25P_DP_bit(FALSE);  // 6
  TOSH_FLASH_M25P_DP_bit(TRUE);   // 7

  TOSH_SET_FLASH_CS_PIN();

  TOSH_SET_SIMO0_PIN();
  TOSH_MAKE_SIMO0_INPUT();
  TOSH_MAKE_UCLK0_INPUT();
}


#undef atomic
void TOSH_SET_PIN_DIRECTIONS(void)
{
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


  TOSH_CLR_TDA_PWDDD_PIN(); // radio has to be on on power-up
  TOSH_MAKE_TDA_PWDDD_OUTPUT();

  TOSH_SET_TDA_ENTDA_PIN(); // deselect the radio
  TOSH_MAKE_TDA_ENTDA_OUTPUT();
  
  TOSH_SET_FLASH_CS_PIN(); // put flash in standby mode
  TOSH_MAKE_FLASH_CS_OUTPUT();
 
  TOSH_SET_POT_SD_PIN(); // put potentiometer in shutdown mode
  TOSH_MAKE_POT_SD_OUTPUT();

  TOSH_SET_POT_EN_PIN(); // deselect potentiometer
  TOSH_MAKE_POT_EN_OUTPUT();

  TOSH_SEL_TEMP_MODFUNC(); //prepare pin for analog excitation from the temperature sensor
  TOSH_MAKE_TEMP_INPUT();
  TOSH_SEL_LIGHT_MODFUNC(); //prepare pin for analog excitation from the light sensor
  TOSH_MAKE_LIGHT_INPUT();

  P1IE = 0;
  P2IE = 0;

  // wait 12ms for the radio and flash to start
  uwait(1024*12);
   //
  // Put the flash in deep sleep state
  TOSH_FLASH_M25P_DP();
  TOSH_SET_TDA_PWDDD_PIN(); // put the radio in sleep
}
}
#endif //TOSH_HARDWARE_H
