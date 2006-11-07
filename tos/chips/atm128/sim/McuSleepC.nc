/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * TOSSIM Implementation of TEP 112 (Microcontroller Power Management)
 * for the Atmega128. It currently does nothing.
 *
 * <pre>
 *  $Id: McuSleepC.nc,v 1.3 2006-11-07 19:30:44 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @date   October 26, 2005
 *
 */

module McuSleepC {
  provides {
    interface McuSleep;
    interface McuPowerState;
  }
  uses {
    interface McuPowerOverride;
  }
}
implementation {
  bool dirty = TRUE;
  mcu_power_t powerState = ATM128_POWER_IDLE;

  /* Note that the power values are maintained in an order
   * based on their active components, NOT on their values.
   * Look at atm128hardware.h and page 42 of the ATmeg128
   * manual (figure 17).*/
  // NOTE: This table should be in progmem.
  const uint8_t atm128PowerBits[ATM128_POWER_DOWN + 1] = {
    0,
    (1 << SM0),
    (1 << SM2) | (1 << SM1) | (1 << SM0),
    (1 << SM1) | (1 << SM0),
    (1 << SM2) | (1 << SM1),
    (1 << SM1)};
    
  mcu_power_t getPowerState() {
    uint8_t diff;
    // Are external timers running?  
    if (TIMSK & ~((1 << OCIE0) | ( 1 << TOIE0))) {
      return ATM128_POWER_IDLE;
    }
    // SPI (Radio stack on mica/micaZ
    else if (READ_BIT(SPCR, SPIE)) { 
      return ATM128_POWER_IDLE;
    }
    // UARTs are active
    else if (UCSR0B & ((1 << TXCIE) | (1 << RXCIE))) { // UART
      return ATM128_POWER_IDLE;
    }
    else if (UCSR1B & ((1 << TXCIE) | (1 << RXCIE))) { // UART
      return ATM128_POWER_IDLE;
    }
    // ADC is enbaled
    else if (READ_BIT(ADCSR, ADEN)) { 
      return ATM128_POWER_ADC_NR;
    }
    // How soon for the timer to go off?
    else if (TIMSK & ((1<<OCIE0) | (1<<TOIE0))) {
      diff = OCR0 - TCNT0;
      if (diff < 16) 
	return ATM128_POWER_IDLE;
      return ATM128_POWER_SAVE;
    }
    else {
      return ATM128_POWER_DOWN;
    }
  }
  
  void computePowerState() {
    powerState = mcombine(getPowerState(),
			  call McuPowerOverride.lowestState());
  }
  
  async command void McuSleep.sleep() {
    if (dirty) {
      uint8_t temp;
      computePowerState();
      //dirty = 0;
      temp = MCUCR;
      temp &= 0xe3;
      temp |= atm128PowerBits[powerState] | (1 << SE);
      MCUCR = temp;
    }
    sei();
    asm volatile ("sleep");
    cli();
  }

  async command void McuPowerState.update() {
    atomic dirty = 1;
  }

 default async command mcu_power_t McuPowerOverride.lowestState() {
   return ATM128_POWER_IDLE;
 }

}
