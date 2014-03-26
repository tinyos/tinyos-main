/** Copyright (c) 2010, University of Szeged
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
* Author: Miklos Maroti
*/

interface SerialComm
{
	/**
	 * Starts a new frame. This command MUST not be called till
	 * the stop command is finished. Implementations may add extra
	 * header bytes transparently. There is no returned error code,
	 * otherwise we cannot guarantee that we can start a new frame.
	 * All errors should be reported in the stopDone event.
	 */
	async command void start();

	/**
	 * Signals the completition of the start command.
	 */
	async event void startDone();

	/**
	 * Sends a new byte within the frame. Implementations may do 
	 * some encoding and transmit more than one byte.
	 */
	async command void data(uint8_t byte);

	/**
	 * Signalled once for each send command.
	 */
	async event void dataDone();

	/**
	 * Finishes the transmission of this frame. Implementations
	 * may add some footer bytes transparently.
	 */
	async command void stop();

	/**
	 * Signals the completion of sending the frame. If there were
	 * any errors during the transmision, then they will be 
	 * signalled here.
	 */
	async event void stopDone(error_t error);
}
