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

generic module Taos2550ReaderP()
{
	provides interface Read<uint16_t> as VisibleLight;
	provides interface Read<uint16_t> as InfraredLight;

	uses interface Resource as VLResource;
	uses interface Resource as IRResource;
	uses interface Read<uint16_t> as VLRead;
	uses interface Read<uint16_t> as IRRead;
}
implementation
{
	command error_t VisibleLight.read() {
		return call VLResource.request();
	}

	event void VLResource.granted() {
		error_t result;
		if ((result = call VLRead.read()) != SUCCESS) {
			call VLResource.release();
			signal VisibleLight.readDone( result, 0 );
		}
	}

	event void VLRead.readDone( error_t result, uint16_t val ) {
		call VLResource.release();
		signal VisibleLight.readDone( result, val );
	}

	command error_t InfraredLight.read() {
		return call IRResource.request();
	}

	event void IRResource.granted() {
		error_t result;
		if ((result = call IRRead.read()) != SUCCESS) {
			call IRResource.release();
			signal InfraredLight.readDone( result, 0 );
		}
	}

	event void IRRead.readDone( error_t result, uint16_t val ) {
		call IRResource.release();
		signal InfraredLight.readDone( result, val );
	}
	
	default event void VisibleLight.readDone( error_t result, uint16_t val ) { }
  	default event void InfraredLight.readDone( error_t result, uint16_t val ) { }
}
