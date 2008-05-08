/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#include <RF230.h>
#include <HplRF230.h>
#include <Tasklet.h>
#include <RadioAssert.h>

module RF230LayerP
{
	provides
	{
		interface Init as PlatformInit @exactlyonce();
		interface Init as SoftwareInit @exactlyonce();

		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
	}

	uses
	{
		interface GeneralIO as SELN;
		interface Resource as SpiResource;

		interface SpiByte;
		interface HplRF230;

		interface GeneralIO as SLP_TR;
		interface GeneralIO as RSTN;

		interface GpioCapture as IRQ;

		interface BusyWait<TMicro, uint16_t>;

		interface RF230Config;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketTimeStamp<TRF230, uint16_t>;
		interface Tasklet;
		interface RadioAlarm;

		async event void lastTouch(message_t* msg);

#ifdef RF230_DEBUG
		interface DiagMsg;
#endif
	}
}

implementation
{
/*----------------- STATE -----------------*/

	tasklet_norace uint8_t state;
	enum
	{
		STATE_P_ON = 0,
		STATE_SLEEP = 1,
		STATE_SLEEP_2_TRX_OFF = 2,
		STATE_TRX_OFF = 3,
		STATE_TRX_OFF_2_RX_ON = 4,
		STATE_RX_ON = 5,
		STATE_BUSY_TX_2_RX_ON = 6,
		STATE_PLL_ON_2_RX_ON = 7,
	};

	tasklet_norace uint8_t cmd;
	enum
	{
		CMD_NONE = 0,			// the state machine has stopped
		CMD_TURNOFF = 1,		// goto SLEEP state
		CMD_STANDBY = 2,		// goto TRX_OFF state
		CMD_TURNON = 3,			// goto RX_ON state
		CMD_TRANSMIT = 4,		// currently transmitting a message
		CMD_RECEIVE = 5,		// currently receiving a message
		CMD_CCA = 6,			// performing clear chanel assesment
		CMD_CHANNEL = 7,		// changing the channel
		CMD_SIGNAL_DONE = 8,	// signal the end of the state transition
		CMD_DOWNLOAD = 9,		// download the received message
	};

	norace bool radioIrq;

	tasklet_norace uint8_t txPower;
	tasklet_norace uint8_t channel;

	tasklet_norace message_t* rxMsg;
	message_t rxMsgBuffer;

	uint16_t capturedTime;	// the current time when the last interrupt has occured

	tasklet_norace uint8_t rssiClear;
	tasklet_norace uint8_t rssiBusy;

/*----------------- REGISTER -----------------*/

	inline void writeRegister(uint8_t reg, uint8_t value)
	{
		ASSERT( call SpiResource.isOwner() );
		ASSERT( reg == (reg & RF230_CMD_REGISTER_MASK) );

		call SELN.clr();
		call HplRF230.spiSplitWrite(RF230_CMD_REGISTER_WRITE | reg);
		call HplRF230.spiSplitReadWrite(value);
		call HplRF230.spiSplitRead();
		call SELN.set();
	}

	inline uint8_t readRegister(uint8_t reg)
	{
		ASSERT( call SpiResource.isOwner() );
		ASSERT( reg == (reg & RF230_CMD_REGISTER_MASK) );

		call SELN.clr();
		call HplRF230.spiSplitWrite(RF230_CMD_REGISTER_READ | reg);
		call HplRF230.spiSplitReadWrite(0);
		reg = call HplRF230.spiSplitRead();
		call SELN.set();

		return reg;
	}

/*----------------- ALARM -----------------*/

	enum
	{
		SLEEP_WAKEUP_TIME = (uint16_t)(880 * RF230_ALARM_MICROSEC),
		CCA_REQUEST_TIME = (uint16_t)(140 * RF230_ALARM_MICROSEC),

		TX_SFD_DELAY = (uint16_t)(176 * RF230_ALARM_MICROSEC),
		RX_SFD_DELAY = (uint16_t)(8 * RF230_ALARM_MICROSEC),
	};

	tasklet_async event void RadioAlarm.fired()
	{
		if( state == STATE_SLEEP_2_TRX_OFF )
			state = STATE_TRX_OFF;
		else if( cmd == CMD_CCA )
		{
			uint8_t cca;

			ASSERT( state == STATE_RX_ON );

			cmd = CMD_NONE;
			cca = readRegister(RF230_TRX_STATUS);

			ASSERT( (cca & RF230_TRX_STATUS_MASK) == RF230_RX_ON );

			signal RadioCCA.done( (cca & RF230_CCA_DONE) ? ((cca & RF230_CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
		}
		else
			ASSERT(FALSE);

		// make sure the rest of the command processing is called
		call Tasklet.schedule();
	}

/*----------------- INIT -----------------*/

	command error_t PlatformInit.init()
	{
		call SELN.makeOutput();
		call SELN.set();
		call SLP_TR.makeOutput();
		call SLP_TR.clr();
		call RSTN.makeOutput();
		call RSTN.set();

		rxMsg = &rxMsgBuffer;

		// these are just good approximates
		rssiClear = 0;
		rssiBusy = 90;

		return SUCCESS;
	}

	command error_t SoftwareInit.init()
	{
		// for powering up the radio
		return call SpiResource.request();
	}

	void initRadio()
	{
		call BusyWait.wait(510);

		call RSTN.clr();
		call SLP_TR.clr();
		call BusyWait.wait(6);
		call RSTN.set();

		writeRegister(RF230_TRX_CTRL_0, RF230_TRX_CTRL_0_VALUE);
		writeRegister(RF230_TRX_STATE, RF230_TRX_OFF);

		call BusyWait.wait(510);

		writeRegister(RF230_IRQ_MASK, RF230_IRQ_TRX_UR | RF230_IRQ_PLL_LOCK | RF230_IRQ_TRX_END | RF230_IRQ_RX_START);
		writeRegister(RF230_CCA_THRES, RF230_CCA_THRES_VALUE);
		writeRegister(RF230_PHY_TX_PWR, RF230_TX_AUTO_CRC_ON | RF230_TX_PWR_DEFAULT);

		txPower = RF230_TX_PWR_DEFAULT;
		channel = call RF230Config.getDefaultChannel() & RF230_CHANNEL_MASK;
		writeRegister(RF230_PHY_CC_CCA, RF230_CCA_MODE_VALUE | channel);

		call SLP_TR.set();
		state = STATE_SLEEP;
	}

/*----------------- SPI -----------------*/

	event void SpiResource.granted()
	{
		call SELN.makeOutput();
		call SELN.set();

		if( state == STATE_P_ON )
		{
			initRadio();
			call SpiResource.release();
		}
		else
			call Tasklet.schedule();
	}

	bool isSpiAcquired()
	{
		if( call SpiResource.isOwner() )
			return TRUE;

		if( call SpiResource.immediateRequest() == SUCCESS )
		{
			call SELN.makeOutput();
			call SELN.set();

			return TRUE;
		}

		call SpiResource.request();
		return FALSE;
	}

/*----------------- CHANNEL -----------------*/

	tasklet_async command error_t RadioState.setChannel(uint8_t c)
	{
		c &= RF230_CHANNEL_MASK;

		if( cmd != CMD_NONE )
			return EBUSY;
		else if( channel == c )
			return EALREADY;

		channel = c;
		cmd = CMD_CHANNEL;
		call Tasklet.schedule();

		return SUCCESS;
	}

	inline void changeChannel()
	{
		ASSERT( cmd == CMD_CHANNEL );
		ASSERT( state == STATE_SLEEP || state == STATE_TRX_OFF || state == STATE_RX_ON );

		if( isSpiAcquired() )
		{
			writeRegister(RF230_PHY_CC_CCA, RF230_CCA_MODE_VALUE | channel);

			if( state == STATE_RX_ON )
				state = STATE_TRX_OFF_2_RX_ON;
			else
				cmd = CMD_SIGNAL_DONE;
		}
	}

/*----------------- TURN ON/OFF -----------------*/

	inline void changeState()
	{
		if( (cmd == CMD_STANDBY || cmd == CMD_TURNON)
			&& state == STATE_SLEEP && call RadioAlarm.isFree() )
		{
			call SLP_TR.clr();

			call RadioAlarm.wait(SLEEP_WAKEUP_TIME);
			state = STATE_SLEEP_2_TRX_OFF;
		}
		else if( cmd == CMD_TURNON && state == STATE_TRX_OFF && isSpiAcquired() )
		{
			ASSERT( ! radioIrq );

			readRegister(RF230_IRQ_STATUS); // clear the interrupt register
			call IRQ.captureRisingEdge();

			writeRegister(RF230_TRX_STATE, RF230_RX_ON);
			state = STATE_TRX_OFF_2_RX_ON;
		}
		else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() )
		{
			writeRegister(RF230_TRX_STATE, RF230_FORCE_TRX_OFF);

			call IRQ.disable();
			radioIrq = FALSE;

			state = STATE_TRX_OFF;
		}

		if( cmd == CMD_TURNOFF && state == STATE_TRX_OFF )
		{
			call SLP_TR.set();
			state = STATE_SLEEP;
			cmd = CMD_SIGNAL_DONE;
		}
		else if( cmd == CMD_STANDBY && state == STATE_TRX_OFF )
			cmd = CMD_SIGNAL_DONE;
	}

	tasklet_async command error_t RadioState.turnOff()
	{
		if( cmd != CMD_NONE )
			return EBUSY;
		else if( state == STATE_SLEEP )
			return EALREADY;

		cmd = CMD_TURNOFF;
		call Tasklet.schedule();

		return SUCCESS;
	}
	
	tasklet_async command error_t RadioState.standby()
	{
		if( cmd != CMD_NONE || (state == STATE_SLEEP && ! call RadioAlarm.isFree()) )
			return EBUSY;
		else if( state == STATE_TRX_OFF )
			return EALREADY;

		cmd = CMD_STANDBY;
		call Tasklet.schedule();

		return SUCCESS;
	}

	tasklet_async command error_t RadioState.turnOn()
	{
		if( cmd != CMD_NONE || (state == STATE_SLEEP && ! call RadioAlarm.isFree()) )
			return EBUSY;
		else if( state == STATE_RX_ON )
			return EALREADY;

		cmd = CMD_TURNON;
		call Tasklet.schedule();

		return SUCCESS;
	}

	default tasklet_async event void RadioState.done() { }

/*----------------- TRANSMIT -----------------*/

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		uint16_t time;
		uint8_t length;
		uint8_t* data;
		uint8_t header;

		if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() || radioIrq )
			return EBUSY;

		if( call RF230Config.requiresRssiCca(msg) 
				&& readRegister(RF230_PHY_RSSI) > ((rssiClear + rssiBusy) >> 3) )
			return EBUSY;

		writeRegister(RF230_TRX_STATE, RF230_PLL_ON);

		// do something useful, just to wait a little
		length = (call PacketTransmitPower.isSet(msg) ?
			call PacketTransmitPower.get(msg) : RF230_DEF_RFPOWER) & RF230_TX_PWR_MASK;

		if( length != txPower )
		{
			txPower = length;
			writeRegister(RF230_PHY_TX_PWR, RF230_TX_AUTO_CRC_ON | txPower);
		}

		// we have missed an incoming message in this short amount of time
		if( (readRegister(RF230_TRX_STATUS) & RF230_TRX_STATUS_MASK) != RF230_PLL_ON )
		{
			ASSERT( (readRegister(RF230_TRX_STATUS) & RF230_TRX_STATUS_MASK) == RF230_BUSY_RX );

			state = STATE_PLL_ON_2_RX_ON;
			return EBUSY;
		}

		atomic
		{
			call SLP_TR.set();
			time = call RadioAlarm.getNow() + TX_SFD_DELAY;
		}
		call SLP_TR.clr();

		ASSERT( ! radioIrq );

		call SELN.clr();
		call HplRF230.spiSplitWrite(RF230_CMD_FRAME_WRITE);

		length = call RF230Config.getLength(msg);
		data = call RF230Config.getPayload(msg);

		// length | data[0] ... data[length-3] | automatically generated FCS
		call HplRF230.spiSplitReadWrite(length);

		// the FCS is atomatically generated (2 bytes)
		length -= 2;

		header = call RF230Config.getHeaderLength();
		if( header > length )
			header = length;

		length -= header;

		// first upload the header
		do {
			call HplRF230.spiSplitReadWrite(*(data++));
		}
		while( --header != 0 );

		call PacketTimeStamp.set(msg, time);
		signal lastTouch(msg);

		do {
			call HplRF230.spiSplitReadWrite(*(data++));
		}
		while( --length != 0 );

		// wait for the SPI transfer to finish
		call HplRF230.spiSplitRead();
		call SELN.set();

		/*
		 * There is a very small window (~1 microsecond) when the RF230 went 
		 * into PLL_ON state but was somehow not properly initialized because 
		 * of an incoming message and could not go into BUSY_TX. I think the
		 * radio can even receive a message, and generate a TRX_UR interrupt
		 * because of concurrent access, but that message probably cannot be
		 * recovered.
		 *
		 * TODO: this needs to be verified, and make sure that the chip is 
		 * not locked up in this case.
		 */

		// go back to RX_ON state when finished
		writeRegister(RF230_TRX_STATE, RF230_RX_ON);

#ifdef RF230_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = call RF230Config.getLength(msg);

			call DiagMsg.str("tx");
			call DiagMsg.uint16(time);
			call DiagMsg.uint8(length);
			call DiagMsg.hex8s(data, length - 2);
			call DiagMsg.send();
		}
#endif

		// wait for the TRX_END interrupt
		state = STATE_BUSY_TX_2_RX_ON;
		cmd = CMD_TRANSMIT;

		return SUCCESS;
	}

	default tasklet_async event void RadioSend.sendDone(error_t error) { }
	default tasklet_async event void RadioSend.ready() { }

/*----------------- CCA -----------------*/

	tasklet_async command error_t RadioCCA.request()
	{
		if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() || ! call RadioAlarm.isFree() )
			return EBUSY;

		// see Errata B7 of the datasheet
		// writeRegister(RF230_TRX_STATE, RF230_PLL_ON);
		// writeRegister(RF230_TRX_STATE, RF230_RX_ON);

		writeRegister(RF230_PHY_CC_CCA, RF230_CCA_REQUEST | RF230_CCA_MODE_VALUE | channel);
		call RadioAlarm.wait(CCA_REQUEST_TIME);
		cmd = CMD_CCA;
		
		return SUCCESS;
	}

	default tasklet_async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

	inline void downloadMessage()
	{
		uint8_t length;
		uint16_t crc;

		call SELN.clr();
		call HplRF230.spiWrite(RF230_CMD_FRAME_READ);

		// read the length byte
		length = call HplRF230.spiWrite(0);

		// if correct length
		if( length >= 3 && length <= call RF230Config.getMaxLength() )
		{
			uint8_t read;
			uint8_t* data;

			// initiate the reading
			call HplRF230.spiSplitWrite(0);

			call RF230Config.setLength(rxMsg, length);
			data = call RF230Config.getPayload(rxMsg);
			crc = 0;

			// we do not store the CRC field
			length -= 2;

			read = call RF230Config.getHeaderLength();
			if( length < read )
				read = length;

			length -= read;

			do {
				crc = call HplRF230.crcByte(crc, *(data++) = call HplRF230.spiSplitReadWrite(0));
			}
			while( --read != 0  );

			if( signal RadioReceive.header(rxMsg) )
			{
				while( length-- != 0 )
					crc = call HplRF230.crcByte(crc, *(data++) = call HplRF230.spiSplitReadWrite(0));

				crc = call HplRF230.crcByte(crc, call HplRF230.spiSplitReadWrite(0));
				crc = call HplRF230.crcByte(crc, call HplRF230.spiSplitReadWrite(0));

				call PacketLinkQuality.set(rxMsg, call HplRF230.spiSplitRead());
			}
			else
				crc = 1;
		}
		else
			crc = 1;

		call SELN.set();
		state = STATE_RX_ON;

#ifdef RF230_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = call RF230Config.getLength(rxMsg);

			call DiagMsg.str("rx");
			call DiagMsg.uint16(call PacketTimeStamp.isSet(rxMsg) ? call PacketTimeStamp.get(rxMsg) : 0);
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.uint8(crc != 0);
			call DiagMsg.uint8(length);
			call DiagMsg.hex8s(call RF230Config.getPayload(rxMsg), length - 2);
			call DiagMsg.send();
		}
#endif
		
		cmd = CMD_NONE;

		// signal only if it has passed the CRC check
		if( crc == 0 )
			rxMsg = signal RadioReceive.receive(rxMsg);
	}

/*----------------- IRQ -----------------*/

	async event void IRQ.captured(uint16_t time)
	{
		ASSERT( ! radioIrq );

		atomic
		{
			capturedTime = time;
			radioIrq = TRUE;
		}

		call Tasklet.schedule();
	}

	void serviceRadio()
	{
		if( isSpiAcquired() )
		{
			uint16_t time;
			uint8_t irq;
			
			atomic time = capturedTime;
			radioIrq = FALSE;
			irq = readRegister(RF230_IRQ_STATUS);

#ifdef RF230_DEBUG
			// TODO: handle this interrupt
			if( irq & RF230_IRQ_TRX_UR )
			{
				if( call DiagMsg.record() )
				{
					call DiagMsg.str("assert ur");
					call DiagMsg.uint16(call RadioAlarm.getNow());
					call DiagMsg.hex8(readRegister(RF230_TRX_STATUS));
					call DiagMsg.hex8(readRegister(RF230_TRX_STATE));
					call DiagMsg.hex8(irq);
					call DiagMsg.uint8(state);
					call DiagMsg.uint8(cmd);
					call DiagMsg.send();
				}
			}
#endif

			if( irq & RF230_IRQ_PLL_LOCK )
			{
				if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
				{
					ASSERT( state == STATE_TRX_OFF_2_RX_ON );

					state = STATE_RX_ON;
					cmd = CMD_SIGNAL_DONE;
				}
				else if( cmd == CMD_TRANSMIT )
				{
					ASSERT( state == STATE_BUSY_TX_2_RX_ON );
				}
				else
					ASSERT(FALSE);
			}

			if( irq & RF230_IRQ_RX_START )
			{
				if( cmd == CMD_CCA )
				{
					signal RadioCCA.done(FAIL);
					cmd = CMD_NONE;
				}

				if( cmd == CMD_NONE )
				{
					ASSERT( state == STATE_RX_ON || state == STATE_PLL_ON_2_RX_ON );

					// the most likely place for busy channel
					rssiBusy += readRegister(RF230_PHY_RSSI) - (rssiBusy >> 2);

					/*
					 * The timestamp corresponds to the first event which could not
					 * have been a PLL_LOCK because then cmd != CMD_NONE, so we must
					 * have received a message (and could also have received the 
					 * TRX_END interrupt in the mean time, but that is fine. Also,
					 * we could not be after a transmission, because then cmd = 
					 * CMD_TRANSMIT.
					 */
					if( irq == RF230_IRQ_RX_START ) // just to be cautious
						call PacketTimeStamp.set(rxMsg, time - RX_SFD_DELAY);
					else
						call PacketTimeStamp.clear(rxMsg);

					cmd = CMD_RECEIVE;
				}
				else
					ASSERT( cmd == CMD_TURNOFF );
			}

			if( irq & RF230_IRQ_TRX_END )
			{
				if( cmd == CMD_TRANSMIT )
				{
					ASSERT( state == STATE_BUSY_TX_2_RX_ON );

					state = STATE_RX_ON;
					cmd = CMD_NONE;
					signal RadioSend.sendDone(SUCCESS);

					// TODO: we could have missed a received message
					ASSERT( ! (irq & RF230_IRQ_RX_START) );
				}
				else if( cmd == CMD_RECEIVE )
				{
					ASSERT( state == STATE_RX_ON || state == STATE_PLL_ON_2_RX_ON );

					if( state == STATE_PLL_ON_2_RX_ON )
					{
						ASSERT( (readRegister(RF230_TRX_STATUS) & RF230_TRX_STATUS_MASK) == RF230_PLL_ON );

						writeRegister(RF230_TRX_STATE, RF230_RX_ON);
						state = STATE_RX_ON;
					}
					else
					{
						// the most likely place for clear channel (hope to avoid acks)
						rssiClear += readRegister(RF230_PHY_RSSI) - (rssiClear >> 2);
					}

					cmd = CMD_DOWNLOAD;
				}
				else
					ASSERT(FALSE);
			}
		}
	}

	default tasklet_async event bool RadioReceive.header(message_t* msg)
	{
		return TRUE;
	}

	default tasklet_async event message_t* RadioReceive.receive(message_t* msg)
	{
		return msg;
	}

/*----------------- TASKLET -----------------*/

	tasklet_async event void Tasklet.run()
	{
		if( radioIrq )
			serviceRadio();

		if( cmd != CMD_NONE )
		{
			if( cmd == CMD_DOWNLOAD )
				downloadMessage();
			else if( CMD_TURNOFF <= cmd && cmd <= CMD_TURNON )
				changeState();
			else if( cmd == CMD_CHANNEL )
				changeChannel();
			
			if( cmd == CMD_SIGNAL_DONE )
			{
				cmd = CMD_NONE;
				signal RadioState.done();
			}
		}

		if( cmd == CMD_NONE && state == STATE_RX_ON && ! radioIrq )
			signal RadioSend.ready();

		if( cmd == CMD_NONE )
			call SpiResource.release();
	}
}
