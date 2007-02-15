#include "mts300.h"
#include "Timer.h"

module AccelP
{
  provides interface Init;
  provides interface StdControl;

  provides interface Atm128AdcConfig as ConfigX;
  provides interface Atm128AdcConfig as ConfigY;
  provides interface ResourceConfigure as ResourceX;
  provides interface ResourceConfigure as ResourceY;

	uses interface GeneralIO as AccelPower;
	uses interface MicaBusAdc as AccelAdcX;
	uses interface MicaBusAdc as AccelAdcY;
}

implementation
{
  command error_t Init.init()
  {
    call AccelPower.makeOutput();
		call AccelPower.clr();

    return SUCCESS;
	}

  command error_t StdControl.start()
  {
    call AccelPower.set();
    return SUCCESS;
  }

  command error_t StdControl.stop()
  {
    call AccelPower.clr();
    call AccelPower.makeInput();

    return SUCCESS;
  }

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

  async command void ResourceX.configure() { }  
  async command void ResourceX.unconfigure() { } 
  async command void ResourceY.configure() { }  
  async command void ResourceY.unconfigure() {}
}