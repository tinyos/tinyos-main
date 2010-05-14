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

generic module Accel202LogicP()
{
	provides interface Read<uint16_t> as XAxis;
	provides interface Read<uint16_t> as YAxis;
	uses interface Resource;
	uses interface Atm128AdcSingle;
	uses interface MicaBusAdc as XADC;
	uses interface MicaBusAdc as YADC;
}
implementation
{
	enum{
		ADCX=1,
		ADCY,
	};

	task void read();
	task void failTask();
	
	error_t performCommand(uint8_t);
	
	uint8_t cmd,readData;

	command error_t XAxis.read() {
		return performCommand(ADCX);
	}
	  
	command error_t YAxis.read() {
		return performCommand(ADCY);
	}

	error_t performCommand(uint8_t Command) {
		cmd=Command;
		return call Resource.request(); 
    }
    
    event void Resource.granted(){
		if(cmd==ADCX){
			call Atm128AdcSingle.getData(call XADC.getChannel(),ATM128_ADC_VREF_OFF,FALSE,ATM128_ADC_PRESCALE);
		}else {
			call Atm128AdcSingle.getData(call YADC.getChannel(),ATM128_ADC_VREF_OFF,FALSE,ATM128_ADC_PRESCALE);
		}	
	}
	
	async event void Atm128AdcSingle.dataReady(uint16_t data, bool precise){
		call Resource.release();
		if (precise){
			atomic readData=data;
			post read();
		}else {
			post failTask();
		}
	}
	
	task void read(){
		atomic{
			if(cmd==ADCX){
				signal XAxis.readDone(SUCCESS,readData);
			}else {
				signal YAxis.readDone(SUCCESS,readData);
			}
		}
	}
	
	task void failTask(){
		if(cmd==ADCX){
			signal XAxis.readDone(FAIL,0);
		}else{
			signal YAxis.readDone(FAIL,0);
		}
	}
}
