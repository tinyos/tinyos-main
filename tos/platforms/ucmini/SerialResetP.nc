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

module SerialResetP
{
	provides 
	{
		interface SerialPacketInfo;
	}

	uses
	{
		interface Send;
		interface Receive;
		interface Leds;
	}
}

implementation
{
	// this is dirty, but we do to save ram
	message_t* sendMsg;

	task void sendAck()
	{
		uint8_t* p = (uint8_t*)sendMsg;

		p[0] = 'Z';
		p[1] = 'B';
		p[2] = 'P';

		if( call Send.send(sendMsg, 3) != SUCCESS )
			post sendAck();
	}

	event void Send.sendDone(message_t* msg, error_t error)
	{
		if( error != SUCCESS )
			post sendAck();
		else
		{
			//void (*bootloader)( void ) = (void*) BOOTLOADER_ADDRESS;
			atomic
			{
				//bootloader();
				wdt_enable(1);
				while(1);
			}
		}
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len)
	{
		uint8_t* p = (uint8_t*)msg;

		if( len == 3 && p[0] == 'R' && p[1] == 'S' && p[2] == 'T' )
		{
			sendMsg = msg;
			post sendAck();
		}

		return msg;
	}

	async command uint8_t SerialPacketInfo.offset()
	{
		return 0;
	}

	async command uint8_t SerialPacketInfo.dataLinkLength(message_t* msg, uint8_t upperLen)
	{
		return upperLen;
	}

	async command uint8_t SerialPacketInfo.upperLength(message_t* msg, uint8_t dataLinkLen)
	{
		return dataLinkLen;
	}
}
