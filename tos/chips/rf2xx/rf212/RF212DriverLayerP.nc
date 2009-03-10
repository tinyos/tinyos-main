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

#include <RF212.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <GenericTimeSyncMessage.h>
#include <RadioConfig.h>

module RF212DriverLayerP
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

		interface FastSpiByte;

		interface GeneralIO as SLP_TR;
		interface GeneralIO as RSTN;

		interface GpioCapture as IRQ;

		interface BusyWait<TMicro, uint16_t>;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;

		interface PacketTimeStamp<TRadio, uint32_t>;
		interface LocalTime<TRadio>;

		interface RF212DriverConfig;
		interface Tasklet;
		interface RadioAlarm;

#ifdef RADIO_DEBUG
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
		CMD_SIGNAL_DONE = 8,		// signal the end of the state transition
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
		ASSERT( reg == (reg & RF212_CMD_REGISTER_MASK) );

		call SELN.clr();
		call FastSpiByte.splitWrite(RF212_CMD_REGISTER_WRITE | reg);
		call FastSpiByte.splitReadWrite(value);
		call FastSpiByte.splitRead();
		call SELN.set();
	}

	inline uint8_t readRegister(uint8_t reg)
	{
		ASSERT( call SpiResource.isOwner() );
		ASSERT( reg == (reg & RF212_CMD_REGISTER_MASK) );

		call SELN.clr();
		call FastSpiByte.splitWrite(RF212_CMD_REGISTER_READ | reg);
		call FastSpiByte.splitReadWrite(0);
		reg = call FastSpiByte.splitRead();
		call SELN.set();

		return reg;
	}

/*----------------- ALARM -----------------*/

	enum
	{
		SLEEP_WAKEUP_TIME = (uint16_t)(880 * RADIO_ALARM_MICROSEC),
		CCA_REQUEST_TIME = (uint16_t)(140 * RADIO_ALARM_MICROSEC),

		TX_SFD_DELAY = (uint16_t)(176 * RADIO_ALARM_MICROSEC),
		RX_SFD_DELAY = (uint16_t)(8 * RADIO_ALARM_MICROSEC),
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
			cca = readRegister(RF212_TRX_STATUS);

			ASSERT( (cca & RF212_TRX_STATUS_MASK) == RF212_RX_ON );

			signal RadioCCA.done( (cca & RF212_CCA_DONE) ? ((cca & RF212_CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
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

		writeRegister(RF212_TRX_CTRL_0, RF212_TRX_CTRL_0_VALUE);
		writeRegister(RF212_TRX_STATE, RF212_TRX_OFF);

		call BusyWait.wait(510);

		writeRegister(RF212_IRQ_MASK, RF212_IRQ_TRX_UR | RF212_IRQ_PLL_LOCK | RF212_IRQ_TRX_END | RF212_IRQ_RX_START);
		writeRegister(RF212_CCA_THRES, RF212_CCA_THRES_VALUE);
		writeRegister(RF212_PHY_TX_PWR, RF212_DEF_RFPOWER);

		txPower = RF212_DEF_RFPOWER;
		channel = call RF212DriverConfig.getDefaultChannel() & RF212_CHANNEL_MASK;
		writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

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

	tasklet_async command uint8_t RadioState.getChannel()
	{
		return channel;
	}

	tasklet_async command error_t RadioState.setChannel(uint8_t c)
	{
		c &= RF212_CHANNEL_MASK;

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
			writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

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

			readRegister(RF212_IRQ_STATUS); // clear the interrupt register
			call IRQ.captureRisingEdge();

			// setChannel was ignored in SLEEP because the SPI was not working, so do it here
			writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

			writeRegister(RF212_TRX_STATE, RF212_RX_ON);
			state = STATE_TRX_OFF_2_RX_ON;
		}
		else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() )
		{
			writeRegister(RF212_TRX_STATE, RF212_FORCE_TRX_OFF);

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
		uint32_t time32;
		void* timesync;

		if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() || radioIrq )
			return EBUSY;

		length = call PacketTransmitPower.isSet(msg) ?
			call PacketTransmitPower.get(msg) : RF212_DEF_RFPOWER;

		if( length != txPower )
		{
			txPower = length;
			writeRegister(RF212_PHY_TX_PWR, txPower);
		}

		if( call RF212DriverConfig.requiresRssiCca(msg) 
				&& (readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK) > ((rssiClear + rssiBusy) >> 3) )
			return EBUSY;

		writeRegister(RF212_TRX_STATE, RF212_PLL_ON);

		// do something useful, just to wait a little
		time32 = call LocalTime.get();
		timesync = call PacketTimeSyncOffset.isSet(msg) ? msg->data + call PacketTimeSyncOffset.get(msg) : 0;

		// we have missed an incoming message in this short amount of time
		if( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) != RF212_PLL_ON )
		{
			ASSERT( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) == RF212_BUSY_RX );

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
		call FastSpiByte.splitWrite(RF212_CMD_FRAME_WRITE);

		length = call RF212DriverConfig.getLength(msg);
		data = call RF212DriverConfig.getPayload(msg);

		// length | data[0] ... data[length-3] | automatically generated FCS
		call FastSpiByte.splitReadWrite(length);

		// the FCS is atomatically generated (2 bytes)
		length -= 2;

		header = call RF212DriverConfig.getHeaderLength();
		if( header > length )
			header = length;

		length -= header;

		// first upload the header to gain some time
		do {
			call FastSpiByte.splitReadWrite(*(data++));
		}
		while( --header != 0 );

		time32 += (int16_t)(time) - (int16_t)(time32);

		if( timesync != 0 )
			*(timesync_relative_t*)timesync = (*(timesync_absolute_t*)timesync) - time32;

		do {
			call FastSpiByte.splitReadWrite(*(data++));
		}
		while( --length != 0 );

		// wait for the SPI transfer to finish
		call FastSpiByte.splitRead();
		call SELN.set();

		/*
		 * There is a very small window (~1 microsecond) when the RF212 went 
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
		writeRegister(RF212_TRX_STATE, RF212_RX_ON);

#ifdef RADIO_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = call RF212DriverConfig.getLength(msg);

			call DiagMsg.str("tx");
			call DiagMsg.uint16(time);
			call DiagMsg.uint8(length);
			call DiagMsg.hex8s(data, length - 2);
			call DiagMsg.send();
		}
#endif

		if( timesync != 0 )
			*(timesync_absolute_t*)timesync = (*(timesync_relative_t*)timesync) + time32;

		call PacketTimeStamp.set(msg, time32);

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
		// writeRegister(RF212_TRX_STATE, RF212_PLL_ON);
		// writeRegister(RF212_TRX_STATE, RF212_RX_ON);

		writeRegister(RF212_PHY_CC_CCA, RF212_CCA_REQUEST | RF212_CCA_MODE_VALUE | channel);
		call RadioAlarm.wait(CCA_REQUEST_TIME);
		cmd = CMD_CCA;
		
		return SUCCESS;
	}

	default tasklet_async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

	inline void downloadMessage()
	{
		uint8_t length;
		uint8_t crc;

		call SELN.clr();
		call FastSpiByte.write(RF212_CMD_FRAME_READ);

		// read the length byte
		length = call FastSpiByte.write(0);

		// if correct length
		if( length >= 3 && length <= call RF212DriverConfig.getMaxLength() )
		{
			uint8_t read;
			uint8_t* data;

			// initiate the reading
			call FastSpiByte.splitWrite(0);

			call RF212DriverConfig.setLength(rxMsg, length);
			data = call RF212DriverConfig.getPayload(rxMsg);
			crc = 0;

			// we do not store the CRC field
			length -= 2;

			read = call RF212DriverConfig.getHeaderLength();
			if( length < read )
				read = length;

			length -= read;

			do {
				*(data++) = call FastSpiByte.splitReadWrite(0);
			}
			while( --read != 0  );

			if( signal RadioReceive.header(rxMsg) )
			{
				while( length-- != 0 )
					*(data++) = call FastSpiByte.splitReadWrite(0);

				call FastSpiByte.splitReadWrite(0);	// two CRC bytes
				call FastSpiByte.splitReadWrite(0);

				call PacketLinkQuality.set(rxMsg, call FastSpiByte.splitReadWrite(0));
				call FastSpiByte.splitReadWrite(0);	// ED
				crc = call FastSpiByte.splitRead() & RF212_RX_CRC_VALID;	// RX_STATUS
			}
		}

		call SELN.set();
		state = STATE_RX_ON;

#ifdef RADIO_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = call RF212DriverConfig.getLength(rxMsg);

			call DiagMsg.str("rx");
			call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.uint8(crc != 0);
			call DiagMsg.uint8(length);
			call DiagMsg.hex8s(call RF212DriverConfig.getPayload(rxMsg), length - 2);
			call DiagMsg.send();
		}
#endif
		
		cmd = CMD_NONE;

		// signal only if it has passed the CRC check
		if( crc != 0 )
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
			uint32_t time32;
			uint8_t irq;
			uint8_t temp;
			
			atomic time = capturedTime;
			radioIrq = FALSE;
			irq = readRegister(RF212_IRQ_STATUS);

#ifdef RADIO_DEBUG
			// TODO: handle this interrupt
			if( irq & RF212_IRQ_TRX_UR )
			{
				if( call DiagMsg.record() )
				{
					call DiagMsg.str("assert ur");
					call DiagMsg.uint16(call RadioAlarm.getNow());
					call DiagMsg.hex8(readRegister(RF212_TRX_STATUS));
					call DiagMsg.hex8(readRegister(RF212_TRX_STATE));
					call DiagMsg.hex8(irq);
					call DiagMsg.uint8(state);
					call DiagMsg.uint8(cmd);
					call DiagMsg.send();
				}
			}
#endif

			if( irq & RF212_IRQ_PLL_LOCK )
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

			if( irq & RF212_IRQ_RX_START )
			{
				if( cmd == CMD_CCA )
				{
					signal RadioCCA.done(FAIL);
					cmd = CMD_NONE;
				}

				if( cmd == CMD_NONE )
				{
					ASSERT( state == STATE_RX_ON || state == STATE_PLL_ON_2_RX_ON );

					// the most likely place for busy channel, with no TRX_END interrupt
					if( irq == RF212_IRQ_RX_START )
					{
						temp = readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK;
						rssiBusy += temp - (rssiBusy >> 2);
#ifndef RF212_RSSI_ENERGY
						call PacketRSSI.set(rxMsg, temp);
					}
					else
					{
						call PacketRSSI.clear(rxMsg);
#endif
					}

					/*
					 * The timestamp corresponds to the first event which could not
					 * have been a PLL_LOCK because then cmd != CMD_NONE, so we must
					 * have received a message (and could also have received the 
					 * TRX_END interrupt in the mean time, but that is fine. Also,
					 * we could not be after a transmission, because then cmd = 
					 * CMD_TRANSMIT.
					 */
					if( irq == RF212_IRQ_RX_START ) // just to be cautious
					{
						time32 = call LocalTime.get();
						time32 += (int16_t)(time - RX_SFD_DELAY) - (int16_t)(time32);
						call PacketTimeStamp.set(rxMsg, time32);
					}
					else
						call PacketTimeStamp.clear(rxMsg);

					cmd = CMD_RECEIVE;
				}
				else
					ASSERT( cmd == CMD_TURNOFF );
			}

			if( irq & RF212_IRQ_TRX_END )
			{
				if( cmd == CMD_TRANSMIT )
				{
					ASSERT( state == STATE_BUSY_TX_2_RX_ON );

					state = STATE_RX_ON;
					cmd = CMD_NONE;
					signal RadioSend.sendDone(SUCCESS);

					// TODO: we could have missed a received message
					ASSERT( ! (irq & RF212_IRQ_RX_START) );
				}
				else if( cmd == CMD_RECEIVE )
				{
					ASSERT( state == STATE_RX_ON || state == STATE_PLL_ON_2_RX_ON );
#ifdef RF212_RSSI_ENERGY
					if( irq == RF212_IRQ_TRX_END )
						call PacketRSSI.set(rxMsg, readRegister(RF212_PHY_ED_LEVEL));
					else
						call PacketRSSI.clear(rxMsg);
#endif
					if( state == STATE_PLL_ON_2_RX_ON )
					{
						ASSERT( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) == RF212_PLL_ON );

						writeRegister(RF212_TRX_STATE, RF212_RX_ON);
						state = STATE_RX_ON;
					}
					else
					{
						// the most likely place for clear channel (hope to avoid acks)
						rssiClear += (readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK) - (rssiClear >> 2);
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
