#include "mts300.h"
#include "Timer.h"
#include "I2C.h"

module MagP
{
  provides interface Init;
  provides interface StdControl;
  provides interface Mag;
  provides interface Atm128AdcConfig as ConfigX;
  provides interface Atm128AdcConfig as ConfigY;
  provides interface ResourceConfigure as ResourceX;
  provides interface ResourceConfigure as ResourceY;

	uses interface GeneralIO as MagPower;
	uses interface MicaBusAdc as MagAdcX;
	uses interface MicaBusAdc as MagAdcY;
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Resource;
}

implementation
{
  uint8_t gainData[2];

  command error_t Init.init()
  {
    call MagPower.makeOutput();
		call MagPower.clr();

    return SUCCESS;
	}

  command error_t StdControl.start()
  {
    call MagPower.set();
    return SUCCESS;
  }

  command error_t StdControl.stop()
  {
    call MagPower.clr();
    call MagPower.makeInput();

    return SUCCESS;
  }

  command error_t Mag.gainAdjustX(uint8_t val)
  {
    gainData[0] = 1;    // pot subaddr
    gainData[1] = val;  // value to write
    return call Resource.request();
  }
  command error_t Mag.gainAdjustY(uint8_t val)
  {
    gainData[0] = 0;    // pot subaddr
    gainData[1] = val;  // value to write
    return call Resource.request();
  }
  /**
  * Resource request
  *
  */
  event void Resource.granted()
  {
    if ( call I2CPacket.write(0x3,TOS_MAG_POT_ADDR, 2, gainData) == SUCCESS)
    {
      return ;
    }
  }
  /**
  * I2CPot2
  *
  */
  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    return ;
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data)
  {
    call Resource.release();
    if (gainData[0] ==1)
    {
      signal Mag.gainAdjustXDone(error);
    }
    if (gainData[0] ==0)
    {
      signal Mag.gainAdjustYDone(error);
    }
    return ;
  }

  async command uint8_t ConfigX.getChannel() {
    return call MagAdcX.getChannel();
  }

  async command uint8_t ConfigX.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t ConfigX.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }

  async command uint8_t ConfigY.getChannel() {
    return call MagAdcY.getChannel();
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