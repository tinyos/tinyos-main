/** Copyright (c) 2009, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zoltan Kincses
*/

module HplIntersema5534P {
	provides interface SplitControl;
	uses interface Channel as ChannelPressurePower;
	uses interface Channel as ChannelPressureClock;
	uses interface Channel as ChannelPressureDin;
	uses interface Channel as ChannelPressureDout;
	uses interface Timer<TMilli>;
	uses interface GeneralIO as SPI_CLK;
	uses interface GeneralIO as SPI_SI;
	uses interface GeneralIO as SPI_SO;
	uses interface Resource;
}
implementation {

	enum{
		IDLE=0,
		START,
		STOP,
	};
	uint8_t state=IDLE;
	
	command error_t SplitControl.start() {
		state=START;
		return call Resource.request();
	}
	
	event void Resource.granted(){
		error_t err;
		if(state==START){
			if((err=call ChannelPressurePower.open())==SUCCESS){
				return;
			}
		}else{
			if((err=call ChannelPressurePower.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
  
	event void ChannelPressurePower.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelPressureClock.open())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelPressureClock.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelPressureDin.open())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelPressureDin.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelPressureDout.open())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelPressureDout.openDone(error_t err){
		state=IDLE;
		call Resource.release();
		if(err==SUCCESS){
			call SPI_CLK.makeOutput();
			call SPI_SI.makeInput();
			call SPI_SI.set();
			call SPI_SO.makeOutput();
			call Timer.startOneShot(300);
			return;
		}
		signal SplitControl.startDone(err);
	}
	
	event void Timer.fired(){
		signal SplitControl.startDone(SUCCESS);
	}
	
	command error_t SplitControl.stop() {
		state=STOP;
		return call Resource.request();
	}
	
	event void ChannelPressurePower.closeDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelPressureClock.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void ChannelPressureClock.closeDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelPressureDin.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void ChannelPressureDin.closeDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelPressureDout.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void ChannelPressureDout.closeDone(error_t err){
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
}
