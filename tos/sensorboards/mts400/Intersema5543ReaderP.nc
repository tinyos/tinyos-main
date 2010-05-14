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

generic module Intersema5543ReaderP()
{
	provides interface Intersema;
	
	uses interface Resource;
	uses interface Read<uint16_t> as TempRead;
	uses interface Read<uint16_t> as PressRead;
	uses interface Calibration as Cal;
}
implementation
{
	int16_t mesResults[2];
	int32_t C1,C2,C3,C4,C5,C6,UT1,dT,T2;
	bool startUP=TRUE;
	
	command error_t Intersema.read() {
		return call Resource.request();
	}

	event void Resource.granted() {
		error_t result;
		if ((result = startUP ? call Cal.getData() : call TempRead.read()) != SUCCESS) {
			call Resource.release();
			signal Intersema.readDone( result, 0 );
		}
		startUP=FALSE;
	}
	
	event void Cal.dataReady(error_t error, uint16_t* calibration){
		if(error==SUCCESS){
			C1=(int32_t)((calibration[0] & 0xFFFE)>>1);
			C2=(int32_t)(((calibration[2] & 0x003F)<<6)|(calibration[3] & 0x003F));
			C3=(int32_t)((calibration[3] & 0xFFC0)>>6);
			C4=(int32_t)((calibration[2] & 0xFFC0)>>6);
			C5=(int32_t)(((calibration[0] & 0x0001)<<10)| ((calibration[1] & 0xFFC0)>>6));
			C6=(int32_t)(calibration[1] & 0x003F);
			UT1=(C5<<3)+20224;
			if ((error = call TempRead.read()) == SUCCESS) {
				return;
			}
		}
		call Resource.release();
		signal Intersema.readDone( error, 0 );
	}
		
	event void TempRead.readDone( error_t error, uint16_t val ) {
		
		if(error==SUCCESS){
			dT=(int32_t)val-UT1;
			mesResults[0]=200+((dT*(C6+50))>>10);
			if(mesResults[0]<200){
				T2=(11*(C6+24)*(200-(int32_t)mesResults[0])*(200-(int32_t)mesResults[0]))>>20;
			}else if (mesResults[0]>450){
				T2=(3*(C6+24)*(450-(int32_t)mesResults[0])*(450-(int32_t)mesResults[0]))>>20;
			}
			else{
				T2=0;
			}
			mesResults[0]-=T2;
			if ((error = call PressRead.read()) == SUCCESS) {
				return;
			}
		}
		call Resource.release();
		signal Intersema.readDone( error, 0);
	}

	event void PressRead.readDone( error_t error, uint16_t val ) {
		
		int32_t SENS,OFF,X;
		
		call Resource.release();
		if(error==SUCCESS){
			OFF=(C2<<2)+(((C4-512)*dT)>>12);
			SENS=C1+((C3*dT)>>10)+24576;
			X=((SENS*((int32_t)val-7168))>>14)-OFF;
			mesResults[1]=(((X*10)>>5)+2500);
			if(mesResults[0]<200){
				mesResults[1]-=3*T2*(((int32_t)mesResults[1]-3500)>>14);
			}else if(mesResults[0]>450){
				mesResults[1]-=T2*(((int32_t)mesResults[1]-10000)>>13);
			}
		}
		signal Intersema.readDone( error, mesResults);
	}
}
