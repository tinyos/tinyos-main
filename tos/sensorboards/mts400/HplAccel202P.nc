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

module HplAccel202P {
	provides interface SplitControl;
	uses interface Channel as DcDcBoost33Channel;
	uses interface Channel as ChannelAccelPower;
	uses interface Channel as ChannelAccel_X;
	uses interface Channel as ChannelAccel_Y;
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
			if((err=call DcDcBoost33Channel.open())==SUCCESS){
				return;
			}
		}else{
			if((err=call DcDcBoost33Channel.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	  
	event void DcDcBoost33Channel.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelAccelPower.open())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelAccelPower.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelAccel_X.open())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelAccel_X.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelAccel_Y.open())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelAccel_Y.openDone(error_t err){
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	command error_t SplitControl.stop() {
		state=STOP;
		return  call Resource.request();
	}
	
	event void DcDcBoost33Channel.closeDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelAccelPower.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void ChannelAccelPower.closeDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelAccel_X.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void ChannelAccel_X.closeDone(error_t err){
		if(err==SUCCESS){
			if((err=call ChannelAccel_Y.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void ChannelAccel_Y.closeDone(error_t err){
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
}
