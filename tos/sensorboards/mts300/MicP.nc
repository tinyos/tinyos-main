/**
 *  Copyright (c) 2005-2006 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS 
 *  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, 
 *  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Hu Siquan <husq@xbow.com> 
 *
 *  $Id: MicP.nc,v 1.1 2007-02-15 10:33:38 pipeng Exp $
 */

#include "Timer.h"
#include "I2C.h"

module MicP
{
  provides interface Init;
  provides interface StdControl;
  provides interface Mic;
  provides interface MicInterrupt;
  provides interface ResourceConfigure as MicResourceConfigure;
  provides interface Atm128AdcConfig as MicAtm128AdcConfig;

  uses interface Leds as DebugLeds;
	uses interface GeneralIO as MicPower;
	uses interface GeneralIO as MicMuxSel;
	uses interface MicaBusAdc as MicAdc;
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Resource;
  uses interface HplAtm128Interrupt as AlertInterrupt;
}
implementation 
{
  uint8_t gainData[2];
  
  command error_t Init.init()
  {
    call MicPower.makeOutput();
		call MicPower.clr();
		call MicMuxSel.makeOutput();    
		call MicMuxSel.clr();
				
    call AlertInterrupt.disable();
    return SUCCESS;
	}

  command error_t StdControl.start()
  {
    call MicPower.set();
    return SUCCESS;
  }
  
  command error_t StdControl.stop()
  {
    call AlertInterrupt.disable();
    call MicPower.clr();
    call MicPower.makeInput();

    return SUCCESS;
  }
  
  /**
  * Resource request
  * 
  */  
  event void Resource.granted()
  {
    call DebugLeds.led0Off();
    if ( call I2CPacket.write(0x3,TOS_MIC_POT_ADDR, 2, gainData) == SUCCESS)
    {
      call DebugLeds.led1On();
    };
  }

  /**
  * mic control
  * 
  */  
  command error_t Mic.muxSel(uint8_t sel)
  {
    if (sel == 0)
    {
      call MicMuxSel.clr();
      return SUCCESS;
    }
    else if (sel == 1)
    {
      call MicMuxSel.set();
      return SUCCESS;
    }
    return FAIL;
  }
  
  command error_t Mic.gainAdjust(uint8_t val)
  {
    call DebugLeds.led0On();
    gainData[0] = 0;    // pot subaddr
    gainData[1] = val;  // value to write
    return call Resource.request();
  }
  
  command uint8_t Mic.readToneDetector()
  {
    bool bVal = call AlertInterrupt.getValue();
    return bVal ? 1 : 0;
  }
  
  /**
  * mic interrupt control
  * 
  */
  async command error_t MicInterrupt.enable()
  {
    call AlertInterrupt.enable();
    return SUCCESS;
  }
  
  async command error_t MicInterrupt.disable()
  {
    call AlertInterrupt.disable();
    return SUCCESS;
  }

  default async event error_t MicInterrupt.toneDetected()
  {
    return SUCCESS;
  }
  
  async event void AlertInterrupt.fired()
  {
    signal MicInterrupt.toneDetected();
  }
  
  /**
  *
  *
  */
  
  async command uint8_t MicAtm128AdcConfig.getChannel() 
  {
    return call MicAdc.getChannel();
  }
  
  async command uint8_t MicAtm128AdcConfig.getRefVoltage() 
  {
    return ATM128_ADC_VREF_OFF;
  }
  
  async command uint8_t MicAtm128AdcConfig.getPrescaler() 
  {
    return ATM128_ADC_PRESCALE;
  }
  
  async command void MicResourceConfigure.configure() 
  {
  	call MicPower.set();
  }
  
  async command void MicResourceConfigure.unconfigure() 
  {
//    call MicPower.clr();
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
    call DebugLeds.led1Off();
    call Resource.release();
    return ;
  }
}





