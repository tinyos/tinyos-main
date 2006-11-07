/* $Id: Atm128AdcConfig.nc,v 1.3 2006-11-07 19:30:44 scipio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "Atm128Adc.h"

/**
 * Clients of the higher-level A/D system must implement this interface to
 * specify which channel to sample, and with what parameters.
 *
 * @author David Gay
 */
interface Atm128AdcConfig {
  /**
   * Obtain channel.
   * @return The A/D channel to use. Must be one of the ATM128_ADC_SNGL_xxx
   *   or ATM128_ADC_DIFF_xxx values from Atm128Adc.h.
   */
  async command uint8_t getChannel();

  /**
   * Obtain reference voltage
   * @return The reference voltage to use. Must be one of the 
   *   ATM128_ADC_VREF_xxx values from Atm128Adc.h.
   */
  async command uint8_t getRefVoltage();

  /**
   * Obtain prescaler value.
   * @return The prescaler value to use. Must be one of the 
   *   ATM128_ADC_PRESCALE_xxx values from Atm128Adc.h.
   */
  async command uint8_t getPrescaler();
}
