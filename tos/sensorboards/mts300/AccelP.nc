/* $Id: AccelP.nc,v 1.1 2007-02-08 17:55:35 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * ADXL202JE accelerometer ADC configuration and power management.
 * @author David Gay <david.e.gay@intel.com>
 */
module AccelP
{
  provides {
    interface SplitControl;
    interface Atm128AdcConfig as ConfigX;
    interface Atm128AdcConfig as ConfigY;
  }
  uses {
    interface Timer<TMilli>;
    interface GeneralIO as AccelPin;
    interface MicaBusAdc as AccelAdcX;
    interface MicaBusAdc as AccelAdcY;
  }
}
implementation
{
  async command uint8_t ConfigX.getChannel() {
    return call AccelAdcX.getChannel();
  }

  async command uint8_t ConfigX.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t ConfigX.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }

  async command uint8_t ConfigY.getChannel() {
    return call AccelAdcY.getChannel();
  }

  async command uint8_t ConfigY.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t ConfigY.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }

  command error_t SplitControl.start() {
    call AccelPin.makeOutput();
    call AccelPin.set();
    /* Startup time is 16.3ms for 0.1uF capacitors,
       according to the ADXL202E data sheet */
    call Timer.startOneShot(17); 
    return SUCCESS;
  }

  event void Timer.fired() {
    signal SplitControl.startDone(SUCCESS);
  }

  task void stopDone() {
    call AccelPin.clr();
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    post stopDone();
    return SUCCESS;
  }
}
