/*
 * Copyright (c) 2007, Vanderbilt University
 * Copyright (c) 2011, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 * Author: Andras Biro
 */

#include <RF212DriverLayer.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
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
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface LinkPacketMetadata;
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
		interface LocalTime<TRadio>;

		interface RF212DriverConfig as Config;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;

		interface PacketTimeStamp<TRadio, uint32_t>;

		interface Tasklet;
		interface RadioAlarm;

#ifdef RADIO_DEBUG
		interface DiagMsg;
#endif
	}
}

implementation
{
	rf212_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call Config.headerLength(msg);
	}

	void* getPayload(message_t* msg)
	{
		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}

	rf212_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

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
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & RF212_CMD_REGISTER_MASK) );
		call SELN.clr();
		call FastSpiByte.splitWrite(RF212_CMD_REGISTER_WRITE | reg);
		call FastSpiByte.splitReadWrite(value);
		call FastSpiByte.splitRead();
		call SELN.set();
	}

	inline uint8_t readRegister(uint8_t reg)
	{
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & RF212_CMD_REGISTER_MASK) );
		call SELN.clr();
		call FastSpiByte.splitWrite(RF212_CMD_REGISTER_READ | reg);
		call FastSpiByte.splitReadWrite(0);
		reg = call FastSpiByte.splitRead();
		call SELN.set();

		return reg;
	}

/*----------------- ALARM -----------------*/

// TODO: these constants are depending on the (changable) physical layer
	enum
	{
		TX_SFD_DELAY = (uint16_t)(177 * RADIO_ALARM_MICROSEC),
		RX_SFD_DELAY = (uint16_t)(8 * RADIO_ALARM_MICROSEC),
	};
	
	tasklet_async event void RadioAlarm.fired()
	{
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
	
	void resetRadio()
	{
		//TODO: all waiting should be optimized in this function
		call BusyWait.wait(15);
		call RSTN.clr();
		call SLP_TR.clr();
		call BusyWait.wait(15);
		call RSTN.set();

		writeRegister(RF212_TRX_CTRL_0, RF212_TRX_CTRL_0_VALUE);
		writeRegister(RF212_TRX_STATE, RF212_TRX_OFF);
		
		//this is way too much (should be done in around 200us), but 510 seemd too short, and it happens quite rarely
		call BusyWait.wait(1000);

		writeRegister(RF212_IRQ_MASK, RF212_IRQ_TRX_UR | RF212_IRQ_PLL_LOCK | RF212_IRQ_TRX_END | RF212_IRQ_RX_START | RF212_IRQ_CCA_ED_DONE);

		// update register values if different from default
		if( RF212_CCA_THRES_VALUE != 0x77 )
			writeRegister(RF212_CCA_THRES, RF212_CCA_THRES_VALUE);

		if( RF212_DEF_RFPOWER != 0x60 )
			writeRegister(RF212_PHY_TX_PWR, RF212_DEF_RFPOWER);

		if( RF212_TRX_CTRL_2_VALUE != RF212_DATA_MODE_DEFAULT )
			writeRegister(RF212_TRX_CTRL_2, RF212_TRX_CTRL_2_VALUE);

		writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);
		state = STATE_TRX_OFF;
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

		writeRegister(RF212_IRQ_MASK, RF212_IRQ_TRX_UR | RF212_IRQ_PLL_LOCK | RF212_IRQ_TRX_END | RF212_IRQ_RX_START | RF212_IRQ_CCA_ED_DONE);

		// update register values if different from default
		if( RF212_CCA_THRES_VALUE != 0x77 )
			writeRegister(RF212_CCA_THRES, RF212_CCA_THRES_VALUE);

		if( RF212_DEF_RFPOWER != 0x60 )
			writeRegister(RF212_PHY_TX_PWR, RF212_DEF_RFPOWER);

		if( RF212_TRX_CTRL_2_VALUE != RF212_DATA_MODE_DEFAULT )
			writeRegister(RF212_TRX_CTRL_2, RF212_TRX_CTRL_2_VALUE);

		txPower = RF212_DEF_RFPOWER;
		channel = RF212_DEF_CHANNEL & RF212_CHANNEL_MASK;
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
		RADIO_ASSERT( cmd == CMD_CHANNEL );
		RADIO_ASSERT( state == STATE_SLEEP || state == STATE_TRX_OFF || state == STATE_RX_ON );

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
		if( (cmd == CMD_STANDBY || cmd == CMD_TURNON) && state == STATE_SLEEP && isSpiAcquired())
		{
			RADIO_ASSERT( ! radioIrq );
			call IRQ.captureRisingEdge();
			state = STATE_SLEEP_2_TRX_OFF;
			call SLP_TR.clr();
		}
		else if( cmd == CMD_TURNON && state == STATE_TRX_OFF && isSpiAcquired() )
		{
			// setChannel was ignored in SLEEP because the SPI was not working, so do it here
			writeRegister(RF212_PHY_CC_CCA, RF212_CCA_MODE_VALUE | channel);

			writeRegister(RF212_TRX_STATE, RF212_RX_ON);
			state = STATE_TRX_OFF_2_RX_ON;
		}
		else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() )
		{
			call IRQ.disable();
			writeRegister(RF212_TRX_STATE, RF212_FORCE_TRX_OFF);
			state = STATE_TRX_OFF;
		}

		if( cmd == CMD_TURNOFF && state == STATE_TRX_OFF )
		{
			readRegister(RF212_IRQ_STATUS); // clear the interrupt register
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
		if( cmd != CMD_NONE )
			return EBUSY;
		else if( state == STATE_TRX_OFF )
			return EALREADY;

		cmd = CMD_STANDBY;
		call Tasklet.schedule();

		return SUCCESS;
	}

	tasklet_async command error_t RadioState.turnOn()
	{
		if( cmd != CMD_NONE )
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

		if( call Config.requiresRssiCca(msg) 
				&& (readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK) > ((rssiClear + rssiBusy) >> 3) )
			return EBUSY;

		writeRegister(RF212_TRX_STATE, RF212_PLL_ON);

		// do something useful, just to wait a little
		timesync = call PacketTimeSyncOffset.isSet(msg) ? ((void*)msg) + call PacketTimeSyncOffset.get(msg) : 0;
		time32 = call LocalTime.get();

		// we have missed an incoming message in this short amount of time
		if( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) != RF212_PLL_ON )
		{
			RADIO_ASSERT( (readRegister(RF212_TRX_STATUS) & RF212_TRX_STATUS_MASK) == RF212_BUSY_RX );

			writeRegister(RF212_TRX_STATE, RF212_RX_ON);
			return EBUSY;
		}
		atomic
		{
			call SLP_TR.set();
			time = call RadioAlarm.getNow();
		}
		call SLP_TR.clr();

		RADIO_ASSERT( ! radioIrq );

		call SELN.clr();
		call FastSpiByte.splitWrite(RF212_CMD_FRAME_WRITE);

		data = getPayload(msg);
		length = getHeader(msg)->length;

		// length | data[0] ... data[length-3] | automatically generated FCS
		call FastSpiByte.splitReadWrite(length);

		// the FCS is atomatically generated (2 bytes), but the rf212 needs two dummy bytes, otherwise it will generate a TRX_UR interrupt
		// length -= 2;

		header = call Config.headerPreloadLength();
		if( header > length )
			header = length;

		length -= header;

		// first upload the header to gain some time
		do {
			call FastSpiByte.splitReadWrite(*(data++));
		}
		while( --header != 0 );

		time32 += (int16_t)(time + TX_SFD_DELAY) - (int16_t)(time32);

		if( timesync != 0 )
			*(timesync_relative_t*)timesync = (*(timesync_absolute_t*)timesync) - time32;

		while( length-- != 0 )
			call FastSpiByte.splitReadWrite(*(data++));

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

		if( timesync != 0 )
			*(timesync_absolute_t*)timesync = (*(timesync_relative_t*)timesync) + time32;

		call PacketTimeStamp.set(msg, time32);

#ifdef RADIO_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = getHeader(msg)->length;

			call DiagMsg.chr('t');
			call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
			call DiagMsg.uint16(call LocalTime.get());
			call DiagMsg.int8(length);
			call DiagMsg.hex8s(getPayload(msg), length-2);
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
		if( cmd != CMD_NONE || state != STATE_RX_ON || ! isSpiAcquired() )
			return EBUSY;

		cmd = CMD_CCA;
		writeRegister(RF212_PHY_CC_CCA, RF212_CCA_REQUEST | RF212_CCA_MODE_VALUE | channel);
		
		return SUCCESS;
	}

	default tasklet_async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

	inline void downloadMessage()
	{
		uint8_t length;
		bool crcValid = FALSE;

		call SELN.clr();
		call FastSpiByte.write(RF212_CMD_FRAME_READ);

		// read the length byte
		length = call FastSpiByte.write(0);

		// if correct length
		if( length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2 )
		{
			uint8_t read;
			uint8_t* data;

			// initiate the reading
			call FastSpiByte.splitWrite(0);

			data = getPayload(rxMsg);
			getHeader(rxMsg)->length = length;

			// we do not store the CRC field
			length -= 2;

			read = call Config.headerPreloadLength();
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
				crcValid = call FastSpiByte.splitRead() & RF212_RX_CRC_VALID;	// RX_STATUS
			}
			else
				call FastSpiByte.splitRead(); // finish the SPI transfer
		}

		call SELN.set();
		state = STATE_RX_ON;

#ifdef RADIO_DEBUG_MESSAGES
		if( call DiagMsg.record() )
		{
			length = getHeader(rxMsg)->length;

			call DiagMsg.chr('r');
			call DiagMsg.uint32(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
			call DiagMsg.uint16(call LocalTime.get());
			call DiagMsg.int8(crcValid ? length : -length);
			call DiagMsg.hex8s(getPayload(rxMsg), length - 2);
			call DiagMsg.int8(call PacketRSSI.isSet(rxMsg) ? call PacketRSSI.get(rxMsg) : -1);
			call DiagMsg.uint8(call PacketLinkQuality.isSet(rxMsg) ? call PacketLinkQuality.get(rxMsg) : 0);
			call DiagMsg.send();
		}
#endif
		
		cmd = CMD_NONE;

		// signal only if it has passed the CRC check
		if( crcValid )
			rxMsg = signal RadioReceive.receive(rxMsg);
	}

/*----------------- IRQ -----------------*/

	async event void IRQ.captured(uint16_t time)
	{
		RADIO_ASSERT( ! radioIrq );

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
			//this is really bad, but unfortunatly sometimes happens (e.g. radio receives a message while turning on). can't found better solution than reset
			if(irq == 0 ){
				RADIO_ASSERT(FALSE);
				if (cmd == CMD_TURNON){
					resetRadio();
					//CMD_TURNON will be restarted at the tasklet when serviceRadio returns
				} else
					RADIO_ASSERT(FALSE);
				/*
				 * We don't care (yet) with CHANNEL, CCA, RECEIVE and TRANSMIT, mostly becouse all of them needs to turn the radio back on, which needs PLL_LOCK irq,
				 * but we don't want to signal RadioState.done()
				 * However it seems most problems happens when turning on the radio
				 */
				return;
			}

#ifdef RADIO_DEBUG
			// TODO: handle this interrupt
			if( irq & RF212_IRQ_TRX_UR )
			{
				if( call DiagMsg.record() )
				{
					call DiagMsg.str("assert ur");
					call DiagMsg.uint16(call LocalTime.get());
					call DiagMsg.hex8(readRegister(RF212_TRX_STATUS));
					call DiagMsg.hex8(readRegister(RF212_TRX_STATE));
					call DiagMsg.hex8(irq);
					call DiagMsg.uint8(state);
					call DiagMsg.uint8(cmd);
					call DiagMsg.send();
				}
			}
#endif

#ifdef RF212_RSSI_ENERGY
			if( irq & RF212_IRQ_TRX_END )
			{
				if( irq == RF212_IRQ_TRX_END || 
					(irq == (RF212_IRQ_RX_START | RF212_IRQ_TRX_END) && cmd == CMD_NONE) )
					call PacketRSSI.set(rxMsg, readRegister(RF212_PHY_ED_LEVEL));
				else
					call PacketRSSI.clear(rxMsg);
			}
#endif

			if ( irq & RF212_IRQ_CCA_ED_DONE)
			{
				if( state == STATE_SLEEP_2_TRX_OFF )
					state = STATE_TRX_OFF;
				else if( cmd == CMD_CCA )
				{
					uint8_t cca;

					RADIO_ASSERT( state == STATE_RX_ON );

					cmd = CMD_NONE;
					cca = readRegister(RF212_TRX_STATUS);

					// sometimes we don't handle yet the RX_START interrupt, but we're already receiving. 
					// It's all right though, CCA reports busy as it should.
					RADIO_ASSERT( (cca & RF212_TRX_STATUS_MASK) == RF212_RX_ON || (cca & RF212_TRX_STATUS_MASK) == RF212_BUSY_RX);
					
					signal RadioCCA.done( (cca & RF212_CCA_DONE) ? ((cca & RF212_CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
				}
				else if( state != STATE_RX_ON ) //if we receive a message during CCA, we will still get this interrupt, but we're already reported FAIL at RX_START
					RADIO_ASSERT(FALSE);
			}
			
//			This should be OK now, since we enable the interrupts in SLEEP state, before changing to TRX_OFF
// 			// sometimes we miss a PLL lock interrupt after turn on
// 			if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
// 			{
// 				RADIO_ASSERT( irq & RF212_IRQ_PLL_LOCK );
// 				RADIO_ASSERT( state == STATE_TRX_OFF_2_RX_ON );
// 
// 				state = STATE_RX_ON;
// 				cmd = CMD_SIGNAL_DONE;
// 			}	else
			if( irq & RF212_IRQ_PLL_LOCK )
			{
				RADIO_ASSERT( state == STATE_TRX_OFF_2_RX_ON );
				if( cmd == CMD_TURNON || cmd == CMD_CHANNEL )
				{
					state = STATE_RX_ON;
					cmd = CMD_SIGNAL_DONE;
				} else 
					RADIO_ASSERT( FALSE );
			}

			if( irq & RF212_IRQ_RX_START )
			{
				if( cmd == CMD_CCA )
				{
					cmd = CMD_NONE;
					signal RadioCCA.done(FAIL);
				}

				if( cmd == CMD_NONE )
				{
					RADIO_ASSERT( state == STATE_RX_ON );

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
					RADIO_ASSERT( cmd == CMD_TURNOFF );
			}

			if( irq & RF212_IRQ_TRX_END )
			{
				if( cmd == CMD_TRANSMIT )
				{
					RADIO_ASSERT( state == STATE_BUSY_TX_2_RX_ON );

					state = STATE_RX_ON;
					cmd = CMD_NONE;
					signal RadioSend.sendDone(SUCCESS);

					// TODO: we could have missed a received message
					RADIO_ASSERT( ! (irq & RF212_IRQ_RX_START) );
				}
				else if( cmd == CMD_RECEIVE )
				{
					RADIO_ASSERT( state == STATE_RX_ON );

					// the most likely place for clear channel (hope to avoid acks)
					rssiClear += (readRegister(RF212_PHY_RSSI) & RF212_RSSI_MASK) - (rssiClear >> 2);

					cmd = CMD_DOWNLOAD;
				}
				else
					RADIO_ASSERT(FALSE);
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

	task void releaseSpi()
	{
		call SpiResource.release();
	}

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
			post releaseSpi();
	}

/*----------------- RadioPacket -----------------*/
	
	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call Config.headerLength(msg) + sizeof(rf212_header_t);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return getHeader(msg)->length - 2;
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		RADIO_ASSERT( 1 <= length && length <= 125 );
		RADIO_ASSERT( call RadioPacket.headerLength(msg) + length + call RadioPacket.metadataLength(msg) <= sizeof(message_t) );

		// we add the length of the CRC, which is automatically generated
		getHeader(msg)->length = length + 2;
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		RADIO_ASSERT( call Config.maxPayloadLength() - sizeof(rf212_header_t) <= 125 );

		return call Config.maxPayloadLength() - sizeof(rf212_header_t);
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call Config.metadataLength(msg) + sizeof(rf212_metadata_t);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		// all flags are automatically cleared
	}

/*----------------- PacketTransmitPower -----------------*/

	async command bool PacketTransmitPower.isSet(message_t* msg)
	{
		return call TransmitPowerFlag.get(msg);
	}

	async command uint8_t PacketTransmitPower.get(message_t* msg)
	{
		return getMeta(msg)->power;
	}

	async command void PacketTransmitPower.clear(message_t* msg)
	{
		call TransmitPowerFlag.clear(msg);
	}

	async command void PacketTransmitPower.set(message_t* msg, uint8_t value)
	{
		call TransmitPowerFlag.set(msg);
		getMeta(msg)->power = value;
	}

/*----------------- PacketRSSI -----------------*/

	async command bool PacketRSSI.isSet(message_t* msg)
	{
		return call RSSIFlag.get(msg);
	}

	async command uint8_t PacketRSSI.get(message_t* msg)
	{
		return getMeta(msg)->rssi;
	}

	async command void PacketRSSI.clear(message_t* msg)
	{
		call RSSIFlag.clear(msg);
	}

	async command void PacketRSSI.set(message_t* msg, uint8_t value)
	{
		// just to be safe if the user fails to clear the packet
		call TransmitPowerFlag.clear(msg);

		call RSSIFlag.set(msg);
		getMeta(msg)->rssi = value;
	}

/*----------------- PacketTimeSyncOffset -----------------*/

	async command bool PacketTimeSyncOffset.isSet(message_t* msg)
	{
		return call TimeSyncFlag.get(msg);
	}

	async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
	{
		return call RadioPacket.headerLength(msg) + call RadioPacket.payloadLength(msg) - sizeof(timesync_absolute_t);
	}

	async command void PacketTimeSyncOffset.clear(message_t* msg)
	{
		call TimeSyncFlag.clear(msg);
	}

	async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value)
	{
		// we do not store the value, the time sync field is always the last 4 bytes
		RADIO_ASSERT( call PacketTimeSyncOffset.get(msg) == value );

		call TimeSyncFlag.set(msg);
	}

/*----------------- PacketLinkQuality -----------------*/

	async command bool PacketLinkQuality.isSet(message_t* msg)
	{
		return TRUE;
	}

	async command uint8_t PacketLinkQuality.get(message_t* msg)
	{
		return getMeta(msg)->lqi;
	}

	async command void PacketLinkQuality.clear(message_t* msg)
	{
	}

	async command void PacketLinkQuality.set(message_t* msg, uint8_t value)
	{
		getMeta(msg)->lqi = value;
	}

/*----------------- LinkPacketMetadata -----------------*/

	async command bool LinkPacketMetadata.highChannelQuality(message_t* msg)
	{
		return call PacketLinkQuality.get(msg) > 200;
	}
}
