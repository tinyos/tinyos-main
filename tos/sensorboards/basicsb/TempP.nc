/* $Id: TempP.nc,v 1.4 2006-12-12 18:23:45 vlahan Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * basicsb thermistor power control and ADC configuration.
 * @author David Gay <david.e.gay@intel.com>
 */
module TempP
{
  provides {
    interface ResourceConfigure;
    interface Atm128AdcConfig;
  }
  uses {
    interface GeneralIO as TempPin;
    interface MicaBusAdc as TempAdc;
  }
}
implementation
{
  async command uint8_t Atm128AdcConfig.getChannel() {
    return call TempAdc.getChannel();
  }

  async command uint8_t Atm128AdcConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t Atm128AdcConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }

  async command void ResourceConfigure.configure() {
    call TempPin.makeOutput();
    call TempPin.set();
  }

  async command void ResourceConfigure.unconfigure() {
    call TempPin.clr();
  }
}
