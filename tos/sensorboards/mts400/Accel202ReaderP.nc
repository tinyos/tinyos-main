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

generic module Accel202ReaderP()
{
	provides interface Read<uint16_t> as X_Axis;
	provides interface Read<uint16_t> as Y_Axis;

	uses interface Resource as X_Resoure;
	uses interface Resource as Y_Resoure;
	uses interface Read<uint16_t> as XRead;
	uses interface Read<uint16_t> as YRead;
}
implementation
{
	command error_t X_Axis.read() {
		return call X_Resoure.request();
	}

	event void X_Resoure.granted() {
		error_t result;
		if ((result = call XRead.read()) != SUCCESS) {
			call X_Resoure.release();
			signal X_Axis.readDone( result, 0 );
		}
	}

	event void XRead.readDone( error_t result, uint16_t val ) {
		call X_Resoure.release();
		signal X_Axis.readDone( result, val );
	}

	command error_t Y_Axis.read() {
		return call Y_Resoure.request();
	}

	event void Y_Resoure.granted() {
		error_t result;
		if ((result = call YRead.read()) != SUCCESS) {
			call Y_Resoure.release();
			signal Y_Axis.readDone( result, 0 );
		}
	}

	event void YRead.readDone( error_t result, uint16_t val ) {
		call Y_Resoure.release();
		signal Y_Axis.readDone( result, val );
	}
	
	default event void X_Axis.readDone( error_t result, uint16_t val ) { }
  	default event void Y_Axis.readDone( error_t result, uint16_t val ) { }	
}
