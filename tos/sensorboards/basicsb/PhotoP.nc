/* $Id: PhotoP.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * basicsb photodiode power control and ADC configuration.
 * @author David Gay <david.e.gay@intel.com>
 */
module PhotoP
{
  provides {
    interface ResourceConfigure;
    interface Atm128AdcConfig;
  }
  uses {
    interface GeneralIO as PhotoPin;
    interface MicaBusAdc as PhotoAdc;
  }
}
implementation
{
  async command uint8_t Atm128AdcConfig.getChannel() {
    return call PhotoAdc.getChannel();
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }

  async command void ResourceConfigure.configure() {
    call PhotoPin.makeOutput();
    call PhotoPin.set();
  }

  async command void ResourceConfigure.unconfigure() {
    call PhotoPin.clr();
  }
}
