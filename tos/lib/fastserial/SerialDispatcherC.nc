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

configuration SerialDispatcherC
{
	provides
	{
		interface SplitControl;
		interface Receive[uart_id_t];
		interface Send[uart_id_t];
	}

	uses
	{
		interface SerialPacketInfo[uart_id_t];
	}

	// TODO: remove these, since they are not used
	provides interface Init;
	uses interface Leds;
	uses interface Init as UnconnectedInit;
	provides interface Leds as UnconnectedLeds;
}

implementation
{
	SplitControl = SerialDispatcherP;
	Receive = SerialDispatcherP;
	Send = SerialDispatcherP;

	Leds = UnconnectedLeds;
	Init = UnconnectedInit;

	components SerialDispatcherP;
	SerialDispatcherP.SubSend -> SerialProtocolP;
	SerialDispatcherP.SubReceive -> SerialProtocolP;
	SerialDispatcherP.SubControl -> SerialAdapterP;
	SerialDispatcherP.SerialPacketInfo = SerialPacketInfo;

	components SerialProtocolP;
	SerialProtocolP.SubSend -> SerialCrcP;
	SerialProtocolP.SubReceive -> SerialCrcP;

	components SerialCrcP;
	SerialCrcP.SubSend -> SerialFrameP.SerialSend;
	SerialCrcP.SubReceive -> SerialBufferP.Receive;

	components SerialBufferP;
	SerialBufferP.SubReceive <- SerialFrameP.SerialReceive;
	SerialBufferP.SerialPacketInfo = SerialPacketInfo;

	components SerialFrameP;
	SerialFrameP.SubSend -> SerialAdapterP.SerialSend;
	SerialFrameP.SubReceive <- SerialAdapterP.SerialReceive;

	components SerialAdapterP;
	SerialAdapterP.UartStream -> PlatformSerialC;
	SerialAdapterP.SubControl -> PlatformSerialC;

	components PlatformSerialC;

#ifdef SERIAL_DEBUG
	components SerialDebugP, LedsC;
	SerialDebugP.Leds -> LedsC;
#endif
}
