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
 *
 *  $Id: SensorMts300P.nc,v 1.5 2007-02-15 10:28:46 pipeng Exp $
 */

#include "Timer.h"

/**
 * This component is the "platform" of the sensorboard space.
 * It handles particulars of initialization, and glues all the
 * member sensor "chips" into one place.  The current implementation
 * is overly monolithic, and should be divided into smaller
 * components that handle each individual sensor.  The temperature
 * and light sensors are tightly coupled however and in the case
 * of the micaz, interfere with the radio (INT2), so more can
 * be done to clean up the design here.
 *
 * @author  Martin Turon
 * @date    October 19, 2005
 */
module SensorMts300P
{
  provides
  {
   	interface Init;                 //!< Standard Initialization
   	interface StdControl;           //!< Start/Stop for Power Management
   	interface Read<uint16_t> as Vref; //!< voltage
   	interface Read<uint16_t> as Temp;  //!< Thermister
   	interface Read<uint16_t> as Light; //!< Photo sensor
   	interface Read<uint16_t> as Microphone; //!< Mic sensor
   	interface Read<uint16_t> as AccelX; //!< Accelerometer sensor
   	interface Read<uint16_t> as AccelY; //!< Accelerometer sensor
   	interface Read<uint16_t> as MagX; //!< magnetometer sensor
   	interface Read<uint16_t> as MagY; //!< magnetometer sensor
  }

  uses
  {
   	interface GeneralIO as TempPower;
   	interface GeneralIO as LightPower;
   	interface StdControl as PhotoControl;
   	interface StdControl as MicControl;
   	interface Mic;
    interface StdControl as MagControl;
    interface Mag;
    interface StdControl as AccelControl;

    interface Read<uint16_t> as VrefRead;
   	interface Read<uint16_t> as TempRead;  //!< Thermister
   	interface Read<uint16_t> as LightRead; //!< Photo sensor
   	interface Read<uint16_t> as MicRead; //!< Mic sensor
   	interface Read<uint16_t> as AccelXRead; //!< Magnetometer sensor
   	interface Read<uint16_t> as AccelYRead; //!< Magnetometer sensor
   	interface Read<uint16_t> as MagXRead; //!< Magnetometer sensor
   	interface Read<uint16_t> as MagYRead; //!< Magnetometer sensor
  	interface Timer<TMilli> as WarmUpTimer;
  }
}
implementation
{
  enum
  {
  	STATE_IDLE = 0,
  	STATE_LIGHT_WARMING,   //!< Powering on sensor
  	STATE_LIGHT_READY,     //!< Power up of sensor complete
  	STATE_LIGHT_SAMPLING,  //!< Sampling sensor
  	STATE_TEMP_WARMING,    //!< Powering on sensor
  	STATE_TEMP_READY,      //!< Power up of sensor complete
  	STATE_TEMP_SAMPLING,   //!< Sampling sensor
  	STATE_MIC_WARMING,    //!< Powering on sensor
  	STATE_MIC_READY,      //!< Power up of sensor complete
  	STATE_MIC_SAMPLING,   //!< Sampling sensor
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

   /**
    * Initialize this component. Initialization should not assume that
    * any component is running: init() cannot call any commands besides
    * those that initialize other components.
    *
    */
    command error_t Init.init()
    {
	    g_flags.flat = STATE_IDLE;
      call Mic.muxSel(1);  // Set the mux so that raw microhpone output is selected
      call Mic.gainAdjust(64);  // Set the gain of the microphone.

	    return SUCCESS;
    }

    /**
     * Start the component and its subcomponents.
     *
     * @return SUCCESS if the component was successfully started.
     */
    command error_t StdControl.start()
    {
      call PhotoControl.start();
      call MicControl.start();
      call MagControl.start();
      call AccelControl.start();
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
	    atomic g_flags.bits.state = STATE_IDLE;

      call PhotoControl.stop();
      call MicControl.stop();
      call MagControl.stop();
      call AccelControl.stop();

	    return SUCCESS;
    }

    /** Turns on the light sensor and turns the thermistor off. */
    void switchLightOn()
    {
    	atomic g_flags.bits.state = STATE_LIGHT_WARMING;
    	call TempPower.clr();
    	call TempPower.makeInput();
    	call LightPower.makeOutput();
    	call LightPower.set();
    	call WarmUpTimer.startOneShot(10);
    }

    /** Turns on the thermistor and turns the light sensor off. */
    void switchTempOn()
    {
    	atomic g_flags.bits.state = STATE_TEMP_WARMING;
    	call LightPower.clr();
    	call LightPower.makeInput();
    	call TempPower.makeOutput();
    	call TempPower.set();
    	call WarmUpTimer.startOneShot(10);
    }

    void switchMicOn()
    {
      atomic g_flags.bits.state = STATE_MIC_WARMING;
      call WarmUpTimer.startOneShot(10);
    }

    task void getLightSample()
    {
    	switch (g_flags.bits.state)
    	{
    	case STATE_IDLE:
    		// Okay, grab the sensor.
    		switchLightOn();
    	  return;
    	case STATE_LIGHT_READY:
    		// Start the sample.
    		atomic { g_flags.bits.state = STATE_LIGHT_SAMPLING; }
    		call LightRead.read();
    	  return;
    	case STATE_LIGHT_WARMING:
    		// Warm-up Timer will switch out of this state.
    	case STATE_LIGHT_SAMPLING:
    		// LightRead.readDone will switch out of this state.
    	  return;
    	}
    }

    task void getTempSample()
    {
    	switch (g_flags.bits.state)
    	{
    	case STATE_IDLE:
    		// Okay, grab the sensor.
    		switchTempOn();
    		return;
    	case STATE_TEMP_READY:
    		// Start the sample.
    		atomic { g_flags.bits.state = STATE_TEMP_SAMPLING; }
    		call TempRead.read();
    		return;
    	case STATE_TEMP_WARMING:
    		// Warm-up Timer will switch out of this state.
    	case STATE_TEMP_SAMPLING:
    		// TempRead.readDone will switch out of this state.
    		return;
    	}
    }

    task void getMicSample()
    {
    	switch (g_flags.bits.state)
    	{
    	case STATE_IDLE:
    		// Okay, grab the sensor.
    		switchMicOn();
    		return;
    	case STATE_MIC_READY:
    		// Start the sample.
    		atomic { g_flags.bits.state = STATE_MIC_SAMPLING; }
    		call MicRead.read();
    		return;
    	case STATE_MIC_WARMING:
    		// Warm-up Timer will switch out of this state.
    	case STATE_MIC_SAMPLING:
    		// MicRead.readDone will switch out of this state.
    		return;
    	}
    }

    /**
     * Start Temperature data acquisition.
     *
     *   This will post a task which will handle sequential states:
     *      WARMING, READY, SAMPLING, DONE (IDLE)
     *   and repost itself until it is completed.
     *
     * @return SUCCESS if request accepted, EBUSY if it is refused
     *    'dataReady' or 'error' will be signaled if SUCCESS is returned
     */
    command error_t Temp.read()
    {
    	post getTempSample();
    	return SUCCESS;
    }
    command error_t Light.read()
    {
    	post getLightSample();
    	return SUCCESS;
    }
    command error_t Microphone.read()
    {
    	post getMicSample();
    	return SUCCESS;
    }
    command error_t Vref.read()
    {
    	call VrefRead.read();
    	return SUCCESS;
    }
    command error_t AccelX.read()
    {
    	//signal AccelX.readDone(SUCCESS,0x1);
    	call AccelXRead.read();
    	return SUCCESS;
    }
    command error_t AccelY.read()
    {
    	//signal AccelY.readDone(SUCCESS,0x2);
    	call AccelYRead.read();
    	return SUCCESS;
    }
    command error_t MagX.read()
    {
    	//signal MagX.readDone(SUCCESS,0x3);
    	call MagXRead.read();
    	return SUCCESS;
    }
    command error_t MagY.read()
    {
    	//signal MagY.readDone(SUCCESS,0x4);
    	call MagYRead.read();
    	return SUCCESS;
    }
    /**
     * Timer to allow either thermistor or light sensor to warm up for 10 msec.
     */
    event void WarmUpTimer.fired()
    {
    	switch (g_flags.bits.state)
    	{
 	    case STATE_LIGHT_WARMING:
    		atomic { g_flags.bits.state = STATE_LIGHT_READY; }
    		post getLightSample();
    		return;

 	    case STATE_TEMP_WARMING:
    		atomic { g_flags.bits.state = STATE_TEMP_READY; }
    		post getTempSample();
    		return;

 	    case STATE_MIC_WARMING:
    		atomic { g_flags.bits.state = STATE_MIC_READY; }
    		post getMicSample();
    		return;

 	    default:
    		//ERROR!!!
    		signal Light.readDone(FAIL,0);
    		signal Temp.readDone(FAIL,0);
    		signal Microphone.readDone(FAIL,0);
      }
    	// Worst case -- return to the IDLE state so next task can progress !!
    	atomic { g_flags.bits.state = STATE_IDLE; }
    }

    /**
     * Data has been acquired.
     * @param result Acquired success flag
     * @param val Acquired value
     */
    event void LightRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
	    switch (g_flags.bits.state)
	    {
	    case STATE_LIGHT_SAMPLING:
		    signal Light.readDone(result,val);
		    break;
	    default: //ERROR!!!
    		signal Light.readDone(FAIL,0);
      }
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
    }

    event void TempRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
	    switch (g_flags.bits.state)
	    {
	    case STATE_TEMP_SAMPLING:
		    signal Temp.readDone(result,val);
		    break;
	    default: //ERROR!!!
    		signal Temp.readDone(FAIL,0);
      }
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
    }

    event void MicRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
	    switch (g_flags.bits.state)
	    {
	    case STATE_MIC_SAMPLING:
		    signal Microphone.readDone(result,val);
		    break;
	    default: //ERROR!!!
    		signal Microphone.readDone(FAIL,0);
      }
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
	 }

    event void VrefRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
		  signal Vref.readDone(result,val);
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
	 }

    event void AccelXRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
		  signal AccelX.readDone(result,val);
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
 	  }

    event void AccelYRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
		  signal AccelY.readDone(result,val);
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
	  }

    event void MagXRead.readDone( error_t result, uint16_t val )
    {
      //val = (val >>6);
      val &= 0x3ff;
		  signal MagX.readDone(result,val);
	    // state must return to IDLE state so next task can progress !!
	    atomic { g_flags.bits.state = STATE_IDLE; }
	 }

   event void MagYRead.readDone( error_t result, uint16_t val )
   {
     //val = (val >>6);
     val &= 0x3ff;
		 signal MagY.readDone(result,val);
	   // state must return to IDLE state so next task can progress !!
	   atomic { g_flags.bits.state = STATE_IDLE; }
	 }

   event error_t Mag.gainAdjustXDone(bool result)
   {
     return result;
   }
   event error_t Mag.gainAdjustYDone(bool result)
   {
     return result;
   }
}





