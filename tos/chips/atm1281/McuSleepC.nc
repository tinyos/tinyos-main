/// $Id: McuSleepC.nc,v 1.1 2007-11-05 20:36:41 sallai Exp $

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
 */

/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/**
 * Implementation of TEP 112 (Microcontroller Power Management) for
 * the Atmega128. Power state calculation code copied from Rob
 * Szewczyk's 1.x code in HPLPowerManagementM.nc.
 *
 * <pre>
 *  $Id: McuSleepC.nc,v 1.1 2007-11-05 20:36:41 sallai Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Robert Szewczyk
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 * @date   October 30, 2007
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
  /* There is no dirty bit management because the sleep mode depends on
     the amount of time remaining in timer2. */

  /* Note that the power values are maintained in an order
   * based on their active components, NOT on their values.
   * Look at atm1281hardware.h and page 54 of the ATmeg1281
   * manual (Table 25).*/
  const_uint8_t atm128PowerBits[ATM128_POWER_DOWN + 1] = {
    0,
    (1 << SM0),
    (1 << SM2) | (1 << SM1) | (1 << SM0),
    (1 << SM1) | (1 << SM0),
    (1 << SM2) | (1 << SM1),
    (1 << SM1)};
    
  mcu_power_t getPowerState() {
    // Note: we go to sleep even if timer 0, 1, 3, 4,  or 5's overflow interrupt
    // is enabled - this allows using these timers as TinyOS "Alarm"s
    // while still having power management.

    // Are external timers running?  
    if (
        TIMSK0 & (1 << OCIE0A | 1 << OCIE0B | 1 << TOIE0) ||
        TIMSK1 & (1 << ICIE1  | 1 << OCIE1A | 1 << OCIE1B | 1 << OCIE1C | 1 << TOIE1) ||
        TIMSK3 & (1 << ICIE3  | 1 << OCIE3A | 1 << OCIE3B | 1 << OCIE3C | 1 << TOIE3) ||
        // input capture and output compare for timer 4 and 5 are
        // not functional on atm1281
        TIMSK4 & (1 << TOIE4) ||
        TIMSK5 & (1 << TOIE5)
    ) {
      return ATM128_POWER_IDLE;
    }    
    // SPI (Radio stack)
    else if (bit_is_set(SPCR, SPIE)) { 
      return ATM128_POWER_IDLE;
    }
    // UARTs are active
    else if (UCSR0B & (1 << TXCIE0 | 1 << RXCIE0)) { // UART
      return ATM128_POWER_IDLE;
    }
    else if (UCSR1B & (1 << TXCIE1 | 1 << RXCIE1)) { // UART
      return ATM128_POWER_IDLE;
    }
    // I2C (Two-wire) is active
    else if (bit_is_set(TWCR, TWEN)){
      return ATM128_POWER_IDLE;
    }    
    // ADC is enabled
    else if (bit_is_set(ADCSRA, ADEN)) { 
      return ATM128_POWER_ADC_NR;
    }
    else {
      return ATM128_POWER_DOWN;
    }
  }

  async command void McuSleep.sleep() {
    uint8_t powerState;

    powerState = mcombine(getPowerState(), call McuPowerOverride.lowestState());
    SMCR =
      (SMCR & 0xf0) | 1 << SE | read_uint8_t(&atm128PowerBits[powerState]);      
    sei();
    asm volatile ("sleep");
    cli();
    
    CLR_BIT(SMCR, SE);
  }

  async command void McuPowerState.update() {
  }

  default async command mcu_power_t McuPowerOverride.lowestState() {
    return ATM128_POWER_DOWN;
  }
}
