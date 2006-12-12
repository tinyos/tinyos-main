// $Id: MeasureClockC.nc,v 1.4 2006-12-12 18:23:42 vlahan Exp $
/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#include <MicaTimer.h>
#include <scale.h>

/**
 * Measure cpu clock frequency at boot time. Provides an Atm128Calibrate
 * interface so that other components can adjust their calibration as
 * needed.
 *
 * @author David Gay
 */

module MeasureClockC {
  provides {
    /**
     * This code MUST be called from PlatformP only, hence the exactlyonce.
     */
    interface Init @exactlyonce();
    interface Atm128Calibrate;
  }
}
implementation 
{
  enum {
    /* This is expected number of cycles per jiffy at the platform's
       specified MHz. Assumes PLATFORM_MHZ == 1, 2, 4, 8 or 16. */
    MAGIC = 488 / (16 / PLATFORM_MHZ)
  };

  uint16_t cycles;

  command error_t Init.init() {
    /* Measure clock cycles per Jiffy (1/32768s) */
    /* This code doesn't use the HPL to avoid timing issues when compiling
       with debugging on */
    atomic
      {
	uint8_t now, wraps;
	uint16_t start;

	/* Setup timer0 to count 32 jiffies, and timer1 cpu cycles */
	TCCR1B = 1 << CS10;
	ASSR = 1 << AS0;
	TCCR0 = 1 << CS01 | 1 << CS00;

	/* Wait for 1s for counter to stablilize after power-up (yes, it
	   really does take that long). That's 122 wrap arounds of timer 1
	   at 8MHz. */
	start = TCNT1;
	for (wraps = MAGIC / 2; wraps; )
	  {
	    uint16_t next = TCNT1;

	    if (next < start)
	      wraps--;
	    start = next;
	  }

	/* Wait for a TCNT0 change */
	now = TCNT0;
	while (TCNT0 == now) ;

	/* Read cpu cycles and wait for next TCNT0 change */
	start = TCNT1;
	now = TCNT0;
	while (TCNT0 == now) ;
	cycles = TCNT1;

	cycles = (cycles - start + 16) >> 5;

	/* Reset to boot state */
	ASSR = TCCR1B = TCCR0 = 0;
	TCNT0 = 0;
	TCNT1 = 0;
	ETIFR = TIFR = 0xff;
	while (ASSR & (1 << TCN0UB | 1 << OCR0UB | 1 << TCR0UB))
	  ;
      }
    return SUCCESS;
  }

  async command uint16_t Atm128Calibrate.cyclesPerJiffy() {
    return cycles;
  }

  async command uint32_t Atm128Calibrate.calibrateMicro(uint32_t n) {
    return scale32(n + MAGIC / 2, cycles, MAGIC);
  }

  async command uint32_t Atm128Calibrate.actualMicro(uint32_t n) {
    return scale32(n + (cycles >> 1), MAGIC, cycles);
  }

  async command uint8_t Atm128Calibrate.adcPrescaler() {
    /* This is also log2(cycles/3.05). But that's a pain to compute */
    if (cycles >= 390)
      return ATM128_ADC_PRESCALE_128;
    if (cycles >= 195)
      return ATM128_ADC_PRESCALE_64;
    if (cycles >= 97)
      return ATM128_ADC_PRESCALE_32;
    if (cycles >= 48)
      return ATM128_ADC_PRESCALE_16;
    if (cycles >= 24)
      return ATM128_ADC_PRESCALE_8;
    if (cycles >= 12)
      return ATM128_ADC_PRESCALE_4;
    return ATM128_ADC_PRESCALE_2;
  }

  async command uint16_t Atm128Calibrate.baudrateRegister(uint32_t baudrate) {
    // value is (cycles*32768) / (8*baudrate) - 1
    return ((uint32_t)cycles << 12) / baudrate - 1;
  }
}
