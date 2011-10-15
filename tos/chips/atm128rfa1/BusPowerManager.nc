/*
* Copyright (c) 2011, University of Szeged
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
* Author: Miklos Maroti, Andras Biro
*/

interface BusPowerManager
{
	/**
	 * Sets the startup and keepalive timeout values in milliseconds.
	 * Only the largest numbers are remembered, as the bus might not
	 * be operational if one of the chips on it is not operational.
	 */
	command void configure(uint16_t startup, uint16_t keepalive);

	/**
	 * Requests to power up this bus. The bus might be already powered
	 * up, in which case the powerOn event will not come.
	 */
	command void requestPower();

	/**
	 * Releases the power up request. You must call this command exactly
	 * the same number of times as you have called requestPower. If other
	 * chips still want to keep the power (e.g. a measurement is in
	 * progress), then powerOff will not be called.
	 */
	command void releasePower();

	/**
	 * This event is called when the bus is powered on and the maximum 
	 * specified startup time has elapsed. Implementations should
	 * initialize the chip or go into power down mode.
	 */
	event void powerOn();

	/**
	 * This event is called when there are no outstanding power requests
	 * and the keepalive timeout value has expired.
	 */
	event void powerOff();
}
