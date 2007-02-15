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
 *  @author Martin Turon <mturon@xbow.com>
 *  @author Hu Siquan <husq@xbow.com>
 *
 *  $Id: PhotoTempP.nc,v 1.2 2007-02-15 10:28:46 pipeng Exp $
 */

#include "Timer.h"

module PhotoTempP
{
  provides
  {
		interface Init;                 									//!< Standard Initialization
		interface StdControl;           //!< Start/Stop for Temp Sensor's Power Management
    interface ResourceConfigure as TempResourceConfigure;
    interface ResourceConfigure as PhotoResourceConfigure;
    interface Atm128AdcConfig as TempAtm128AdcConfig;
    interface Atm128AdcConfig as PhotoAtm128AdcConfig;
  }
  uses
  {
  	interface GeneralIO as TempPower;
  	interface GeneralIO as LightPower;
  	interface MicaBusAdc as SensorAdc;
  	interface Leds as DebugLeds;
    }
}
implementation
{
/*
    enum
    {
    	STATE_IDLE = 0,
    	STATE_LIGHT_WARMING,   //!< Powering on sensor
    	STATE_LIGHT_READY,     //!< Power up of sensor complete
    	STATE_LIGHT_SAMPLING,  //!< Sampling sensor
    	STATE_TEMP_WARMING,    //!< Powering on sensor
    	STATE_TEMP_READY,      //!< Power up of sensor complete
    	STATE_TEMP_SAMPLING,   //!< Sampling sensor
    };

    /// Yes, this could be a simple uint8_t.  There used to be more bits here,
    /// but they were optimized out and removed.
    union
    {
    	uint8_t flat;
    	struct
    	{
  	    uint8_t state       : 4;   //!< sensorboard state
  	  } bits;
    } g_flags;
*/

    void inline TOSH_uwait(int u_sec)
    {
      /* In most cases (constant arg), the test is elided at compile-time */
      if (u_sec)
        /* loop takes 4 cycles, aka 1us */
        asm volatile (
    "1:	sbiw	%0,1\n"
    "	brne	1b" : "+w" (u_sec));
    }
   /**
    * Initialize this component. Initialization should not assume that
    * any component is running: init() cannot call any commands besides
    * those that initialize other components.
    *
    */
    command error_t Init.init()
    {
	    return SUCCESS;
    }


    /**
     * Start the component and its subcomponents.
     *
     * @return SUCCESS if the component was successfully started.
     */
    command error_t StdControl.start()
    {
      call TempPower.makeOutput();
    	call TempPower.clr();
    	call LightPower.makeOutput();
    	call LightPower.clr();
    	
    	return SUCCESS;
    }

    /**
     * Stop the component and pertinent subcomponents (not all
     * subcomponents may be turned off due to wakeup timers, etc.).
     *
     * @return SUCCESS if the component was successfully stopped.
     */
    command error_t StdControl.stop()
    {
    	call TempPower.clr();
    	call LightPower.clr();
    	call TempPower.makeInput();
    	call LightPower.makeInput();
    	
    	return SUCCESS;
    }

    async command uint8_t TempAtm128AdcConfig.getChannel() 
    {
      return call SensorAdc.getChannel();
    }
  
    async command uint8_t TempAtm128AdcConfig.getRefVoltage() 
    {
      return ATM128_ADC_VREF_OFF;
    }
  
    async command uint8_t TempAtm128AdcConfig.getPrescaler() 
    {
      return ATM128_ADC_PRESCALE;
    }
  
    async command uint8_t PhotoAtm128AdcConfig.getChannel() 
    {
      return call SensorAdc.getChannel();
    }
  
    async command uint8_t PhotoAtm128AdcConfig.getRefVoltage() 
    {
      return ATM128_ADC_VREF_OFF;
    }
  
    async command uint8_t PhotoAtm128AdcConfig.getPrescaler() 
    {
      return ATM128_ADC_PRESCALE;
    }
  
    async command void TempResourceConfigure.configure() 
    {
      call DebugLeds.led0On();
  		call LightPower.clr();
  		call LightPower.makeInput();
  		call TempPower.makeOutput();
  		call TempPower.set();
  		TOSH_uwait(1000);
    }
  
    async command void TempResourceConfigure.unconfigure() 
    {
      call DebugLeds.led0Off();
  		call TempPower.clr();
  		call TempPower.makeInput();
    }
  
      /** Turns on the light sensor and turns the thermistor off. */
    async command void PhotoResourceConfigure.configure() 
    {
      call DebugLeds.led1On();
  		call TempPower.clr();
  		call TempPower.makeInput();
  		call LightPower.makeOutput();
  		call LightPower.set();
  		TOSH_uwait(1000);
    }
  
    async command void PhotoResourceConfigure.unconfigure() 
    {
      call DebugLeds.led1Off();
  		call LightPower.clr();
  		call LightPower.makeInput();
    }
}
