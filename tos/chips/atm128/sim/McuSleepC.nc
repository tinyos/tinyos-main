/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 * TOSSIM Implementation of TEP 112 (Microcontroller Power Management)
 * for the Atmega128. It currently does nothing.
 *
 * <pre>
 *  $Id: McuSleepC.nc,v 1.6 2010-06-29 22:07:43 scipio Exp $
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
    // All of memory may change at this point...
    asm volatile ("sleep" : : : "memory");
    cli();
  }

  async command void McuPowerState.update() {
    atomic dirty = 1;
  }

 default async command mcu_power_t McuPowerOverride.lowestState() {
   return ATM128_POWER_IDLE;
 }

}
