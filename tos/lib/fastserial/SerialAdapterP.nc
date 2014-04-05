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

#include "SerialDebug.h"

module SerialAdapterP
{
	provides
	{
		interface SplitControl;
		interface SerialComm as SerialSend;
	}

	uses
	{
		interface SerialComm as SerialReceive;

		interface UartStream;
		interface StdControl as SubControl;
	}
}

implementation
{
// ------- State

	enum
	{
		RXSTATE_OFF = 0,
		RXSTATE_STARTDONE = 1,
		RXSTATE_STOPDONE = 2,
		RXSTATE_ON = 3,
		RXSTATE_SEND = 4,
	};

	norace uint8_t rxState;

	enum
	{
		TXSTATE_OFF = 0,
		TXSTATE_STARTED = 0x01,
		TXSTATE_ERROR = 0x02,
		TXSTATE_SENDDONE = 0x04,
		TXSTATE_PENDING = 0x08,
		TXSTATE_STARTDONE = 0x10,
		TXSTATE_STOPDONE = 0x20,
	};

	norace uint8_t txState;

	task void signalDone()
	{
		if( (txState & TXSTATE_STARTDONE) != 0 )
		{
			txState &= ~TXSTATE_STARTDONE;
			signal SerialSend.startDone();
		}
		else if( (txState & TXSTATE_STOPDONE) != 0 )
		{
			error_t error = (txState & TXSTATE_ERROR) != 0 ? FAIL : SUCCESS;

			txState = TXSTATE_OFF;

			signal SerialSend.stopDone(error);
		}

		if( rxState == RXSTATE_STARTDONE )
		{
			rxState = RXSTATE_ON;
			signal SplitControl.startDone(SUCCESS);
		}
		else if( rxState == RXSTATE_STOPDONE )
		{
			rxState = RXSTATE_OFF;
			signal SplitControl.stopDone(SUCCESS);
		}
	}

// ------- Receive

	command error_t SplitControl.start()
	{
		if( rxState != RXSTATE_OFF )
			return EALREADY;

		SERIAL_ASSERT( txState == TXSTATE_OFF );

		if( call SubControl.start() == SUCCESS )
		{
			rxState = RXSTATE_STARTDONE;
			call SerialReceive.start();

			return SUCCESS;
		}

		return FAIL;
	}

	command error_t SplitControl.stop()
	{
		if( rxState != RXSTATE_ON )
			return EALREADY;

		if( txState != TXSTATE_OFF )
			return EBUSY;

		if( call SubControl.stop() == SUCCESS )
		{
			rxState = RXSTATE_STOPDONE;
			call SerialReceive.stop();

			return SUCCESS;
		}

		return FAIL;
	}

	async event void SerialReceive.startDone()
	{
		SERIAL_ASSERT( rxState == RXSTATE_STARTDONE );
		post signalDone();
	}

	async event void SerialReceive.stopDone(error_t error)
	{
		SERIAL_ASSERT( rxState == RXSTATE_STOPDONE );
		post signalDone();
	}

	async event void UartStream.receivedByte(uint8_t byte)
	{
#ifdef SERIAL_DEBUG
		SERIAL_ASSERT( rxState == RXSTATE_ON );
		rxState = RXSTATE_SEND;
#endif

		call SerialReceive.data(byte);

		SERIAL_ASSERT( rxState == RXSTATE_ON );
	}

	async event void SerialReceive.dataDone()
	{
#ifdef SERIAL_DEBUG
		SERIAL_ASSERT( rxState == RXSTATE_SEND );
		rxState = RXSTATE_ON;
#endif
	}

	async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error)
	{
	}

// ------- Send	

	norace uint8_t txByte;

	async command void SerialSend.start()
	{
		SERIAL_ASSERT( txState == TXSTATE_OFF );
		SERIAL_ASSERT( rxState == RXSTATE_ON || rxState == RXSTATE_SEND );

		txState = TXSTATE_STARTED | TXSTATE_STARTDONE;
		post signalDone();
	}

	async command void SerialSend.data(uint8_t byte)
	{
		SERIAL_ASSERT( (txState & TXSTATE_STARTED) != 0 && (txState & TXSTATE_PENDING) == 0 );

		txByte = byte;

		if( call UartStream.send( &txByte, 1 ) != SUCCESS )
			txState |= TXSTATE_ERROR;
	}

	async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error)
	{
		SERIAL_ASSERT( (txState & TXSTATE_STARTED) != 0 && (txState & TXSTATE_PENDING) == 0 );

		if( error != SUCCESS )
			txState |= TXSTATE_ERROR;

		if( (txState & TXSTATE_SENDDONE) == 0 )
		{
			txState |= TXSTATE_SENDDONE;

			// keep delivering sendDone events if the interrupt has occured again while it was executing
			do
			{
				signal SerialSend.dataDone();

				atomic
				{
					if( (txState & TXSTATE_PENDING) != 0 )
						txState &= ~TXSTATE_PENDING;
					else
						txState &= ~TXSTATE_SENDDONE;
				}
			} while( (txState & TXSTATE_SENDDONE) != 0 );
		}
		else // we have reentered twice
			txState |= TXSTATE_PENDING;
	}

	async command void SerialSend.stop()
	{
		SERIAL_ASSERT( (txState & TXSTATE_STARTED) != 0 && (txState & TXSTATE_PENDING) == 0 );

		// it is possible that TXSTATE_SENDDONE is on, so we have to signal stopDone from a task
		txState |= TXSTATE_STOPDONE;
		post signalDone();
	}
}
