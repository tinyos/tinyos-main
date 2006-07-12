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
 * Implementation of TEP 112 (Microcontroller Power Management) for
 * the MSP430. Code for low power calculation copied from older
 * msp430hardware.h by Vlado Handziski, Joe Polastre, and Cory Sharp.
 *
 *
 * @author Philip Levis
 * @author Vlado Handziski
 * @author Joe Polastre
 * @author Cory Sharp
 * @date   October 26, 2005
 * @see  Please refer to TEP 112 for more information about this component and its
 *          intended use.
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
  mcu_power_t powerState = MSP430_POWER_ACTIVE;

  /* Note that the power values are maintained in an order
   * based on their active components, NOT on their values.
   * Look at atm128hardware.h and page 42 of the ATmeg128
   * manual (figure 17).*/
  // NOTE: This table should be in progmem.
  const uint16_t msp430PowerBits[MSP430_POWER_LPM4 + 1] = {
    0,                                       // ACTIVE
    SR_CPUOFF,                               // LPM0
    SR_SCG0+SR_CPUOFF,                       // LPM1
    SR_SCG1+SR_CPUOFF,                       // LPM2
    SR_SCG1+SR_SCG0+SR_CPUOFF,               // LPM3
    SR_SCG1+SR_SCG0+SR_OSCOFF+SR_CPUOFF,     // LPM4
  };
    
  mcu_power_t getPowerState() {
    mcu_power_t pState = MSP430_POWER_LPM3;
    // TimerA, USART0, USART1 check
    if ((((TACCTL0 & CCIE) ||
	  (TACCTL1 & CCIE) ||
	  (TACCTL2 & CCIE)) &&
	 ((TACTL & TASSEL_3) == TASSEL_2)) ||
	((ME1 & (UTXE0 | URXE0)) && (U0TCTL & SSEL1)) ||
	((ME2 & (UTXE1 | URXE1)) && (U1TCTL & SSEL1))
#ifdef __msp430_have_usart0_with_i2c
	 // registers end in "nr" to prevent nesC race condition detection
	 || ((U0CTLnr & I2CEN) && (I2CTCTLnr & SSEL1) &&
	     (I2CDCTLnr & I2CBUSY) && (U0CTLnr & SYNC) && (U0CTLnr & I2C))
#endif
	)
      pState = MSP430_POWER_LPM1;
    // ADC12 check
    if (ADC12CTL1 & ADC12BUSY){
      if (!(ADC12CTL0 & MSC) && ((TACTL & TASSEL_3) == TASSEL_2))
	pState = MSP430_POWER_LPM1;
      else
        switch (ADC12CTL1 & ADC12SSEL_3) {
	case ADC12SSEL_2:
	  pState = MSP430_POWER_ACTIVE;
	  break;
	case ADC12SSEL_3:
	  pState = MSP430_POWER_LPM1;
	  break;
        }
    }
    return pState;
  }
  
  void computePowerState() {
    powerState = mcombine(getPowerState(),
			  call McuPowerOverride.lowestState());
  }
  
  async command void McuSleep.sleep() {
    uint16_t temp;
    if (dirty) {
      computePowerState();
      //dirty = 0;
    }
    temp = msp430PowerBits[powerState] | SR_GIE;
    __asm__ __volatile__( "bis  %0, r2" : : "m" (temp) );
    __nesc_disable_interrupt();
  }

  async command void McuPowerState.update() {
    atomic dirty = 1;
  }

 default async command mcu_power_t McuPowerOverride.lowestState() {
   return MSP430_POWER_LPM4;
 }

}
