/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 * Copyright (c) 2007, Vanderbilt University
 * Copyright (c) 2010, University of Szeged
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

/**
 * @author Philip Levis
 * @author Robert Szewczyk
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

module McuSleepC @safe()
{
  provides {
    interface McuSleep;
    interface McuPowerState;
  }
  uses {
    interface McuPowerOverride;
    interface Leds @atmostonce();
  }
}

implementation
{
  /* Note that the power values are maintained in an order
   * based on their active components, NOT on their values.
   * Look at atm1281hardware.h and page 54 of the ATmeg1281
   * manual (Table 25).*/
  const_uint8_t atm128PowerBits[ATM128_POWER_DOWN + 1] = {
    0,	//IDLE
    (1 << SM0),	//ADC_NR
    (1 << SM2) | (1 << SM1) | (1 << SM0),	//EXT_STDBY
    (1 << SM1) | (1 << SM0),	//POWER_SAVE
    (1 << SM2) | (1 << SM1),	//STDBY
    (1 << SM1)	//POWER_DOWN
  };

  norace int8_t powerState = -1;

  async command void McuSleep.sleep()
  {
    if( powerState < 0 ) {
      powerState = call McuPowerOverride.lowestState();
      SMCR = (SMCR & 0xf0) | read_uint8_t(&atm128PowerBits[powerState]);
    }

#ifdef TOGGLE_ON_SLEEP
    if( powerState >= ATM128_POWER_SAVE )
      call Leds.led0Off();
#endif

    SET_BIT(SMCR, SE);

    sei();
    // All of memory may change at this point...
    asm volatile ("sleep" : : : "memory");
    cli();

    CLR_BIT(SMCR, SE);

#ifdef TOGGLE_ON_SLEEP
    call Leds.led0On();
#endif
  }

  async command void McuPowerState.update()
  {
   	powerState = -1;
  }

  default async command mcu_power_t McuPowerOverride.lowestState()
  {
    return ATM128_POWER_DOWN;
  }
}
