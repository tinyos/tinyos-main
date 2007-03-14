#include "mts300.h"
#include "Timer.h"
#include "I2C.h"

module MagP
{
  provides interface SplitControl;
  provides interface Mag;
  provides interface Atm128AdcConfig as ConfigX;
  provides interface Atm128AdcConfig as ConfigY;

  uses interface Timer<TMilli>;
	uses interface GeneralIO as MagPower;
	uses interface MicaBusAdc as MagAdcX;
	uses interface MicaBusAdc as MagAdcY;
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Resource as I2CResource;
}

implementation
{
  uint8_t gainData[2];

  command error_t SplitControl.start()
  {
    call MagPower.makeOutput();
    call MagPower.set();

    call Timer.startOneShot(100); 
    return SUCCESS;
  }

  event void Timer.fired() {
    signal SplitControl.startDone(SUCCESS);
  }

  command error_t SplitControl.stop()
  {
    call MagPower.clr();
    call MagPower.makeInput();

    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mag.gainAdjustX(uint8_t val)
  {
    gainData[0] = 1;    // pot subaddr
    gainData[1] = val;  // value to write
    return call I2CResource.request();
  }
  command error_t Mag.gainAdjustY(uint8_t val)
  {
    gainData[0] = 0;    // pot subaddr
    gainData[1] = val;  // value to write
    return call I2CResource.request();
  }
  /**
  * Resource request
  *
  */
  event void I2CResource.granted()
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
    call I2CResource.release();
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

   default event error_t Mag.gainAdjustXDone(bool result)
   {
     return result;
   }
   default event error_t Mag.gainAdjustYDone(bool result)
   {
     return result;
   }
}