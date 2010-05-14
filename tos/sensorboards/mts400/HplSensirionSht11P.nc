/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "Timer.h"

/**
 * HplSensirionSht11P is a low-level component that controls power for
 * the Sensirion SHT11 sensor on the telosb platform.
 *
 * @author Gilman Tolle <gtolle@archrock.com>
 * @version $Revision: 1.1 $ $Date: 2010-05-14 13:33:14 $
 */

module HplSensirionSht11P {
	provides interface SplitControl;
	uses interface Timer<TMilli>;
	uses interface Channel as ChannelHumidityClock;
	uses interface Channel as ChannelHumidityData;
	uses interface Channel as ChannelHumidityPower;
	uses interface GeneralIO as DATA;
	uses interface GeneralIO as SCK;
}
implementation {

	command error_t SplitControl.start() {
		return call ChannelHumidityClock.open();
	}
  
	event void ChannelHumidityClock.openDone(error_t err){
		if (err==SUCCESS){
			call ChannelHumidityData.open();
			return;
		}
		signal SplitControl.startDone( err );
	}
  
	event void ChannelHumidityData.openDone(error_t err){
		if (err==SUCCESS){
			call ChannelHumidityPower.open();
			return;
		}
		signal SplitControl.startDone( err );
	}
	
	event void ChannelHumidityPower.openDone(error_t err){
		if (err==SUCCESS){
			call Timer.startOneShot(11);
			return;
		}
		signal SplitControl.startDone( err );
	}

	event void Timer.fired(){
		signal SplitControl.startDone( SUCCESS );
	}

	command error_t SplitControl.stop(){
		call SCK.makeInput();
		call SCK.clr();
		call DATA.makeInput();
		call DATA.clr();
		return call ChannelHumidityClock.close();
	}
	
	event void ChannelHumidityClock.closeDone(error_t err){
		if (err==SUCCESS){
			call ChannelHumidityData.close();
			return;
		}
		signal SplitControl.stopDone( err );
	}
  
	event void ChannelHumidityData.closeDone(error_t err){
		if (err==SUCCESS){
			call ChannelHumidityPower.close();
			return;
		}
		signal SplitControl.stopDone( err );
	}
	
	event void ChannelHumidityPower.closeDone(error_t err){
		signal SplitControl.stopDone( err );
	}
}
