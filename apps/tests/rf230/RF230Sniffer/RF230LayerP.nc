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
		interface Init as PlatformInit;
		interface Init as SoftwareInit;

		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioWait;
		interface Tasklet as RadioTasklet;
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
		interface Alarm<TRF230, uint16_t>;

		interface BusyWait<TMicro, uint16_t>;

		interface RF230Config;
		interface Tasklet;

		interface DiagMsg;
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
	};

	tasklet_norace uint8_t cmd;
	enum
	{
		CMD_NONE = 0,			// the state machine has stopped
		CMD_WAIT = 1,			// RadioWait timeout is irqs
		CMD_TURNOFF = 2,		// goto SLEEP state
		CMD_STANDBY = 3,		// goto TRX_OFF state
		CMD_TURNON = 4,			// goto RX_ON state
		CMD_TRANSMIT = 5,		// currently transmitting a message
		CMD_RECEIVE = 6,		// currently receiving a message
		CMD_CCA = 7,			// performing clear chanel assesment
		CMD_CHANNEL = 8,		// changing the channel
		CMD_SIGNAL_DONE = 9,	// signal the end of the state transition
		CMD_DOWNLOAD = 10,		// download the received message
	};

	uint8_t interrupts;
	enum
	{
		IRQ_ALARM = 0x01,
		IRQ_RADIO = 0x02,
	};

	inline uint8_t getInterrupts()
	{
		uint8_t s;
		atomic s = interrupts;
		return s;
	}

	tasklet_norace uint8_t txPower;
	tasklet_norace uint8_t channel;

	tasklet_norace message_t* rxMsg;
	message_t rxMsgBuffer;

	uint16_t capturedTime;	// the current time when the last interrupt has occured

/*----------------- REGISTER -----------------*/

	inline void writeRegister(uint8_t reg, uint8_t value)
	{
		ASSERT( call SpiResource.isOwner() );

		reg = RF230_CMD_REGISTER_WRITE | (reg & RF230_CMD_REGISTER_MASK);

		call SELN.clr();
		call HplRF230.spiWrite(reg);
		call HplRF230.spiWrite(value);
		call SELN.set();
	}

	inline uint8_t readRegister(uint8_t reg)
	{
		ASSERT( call SpiResource.isOwner() );

		reg = RF230_CMD_REGISTER_READ | (reg & RF230_CMD_REGISTER_MASK);

		call SELN.clr();
		call HplRF230.spiWrite(reg);
		reg = call HplRF230.spiWrite(0);
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

	void startAlarm(uint16_t time)
	{
		call Alarm.start(time);
	}

	async event void Alarm.fired()
	{
		ASSERT( ! (getInterrupts() & IRQ_ALARM) );

		atomic interrupts |= IRQ_ALARM;
		call Tasklet.schedule();
	}

	inline void serviceAlarm()
	{
		if( state == STATE_SLEEP_2_TRX_OFF )
			state = STATE_TRX_OFF;
		else if( cmd == CMD_CCA )
		{
			uint8_t cca;

			ASSERT( state == STATE_RX_ON );

			cmd = CMD_NONE;
			cca = readRegister(RF230_TRX_STATUS);

			signal RadioCCA.done( (cca & RF230_CCA_DONE) ? ((cca & RF230_CCA_STATUS) ? SUCCESS : EBUSY) : FAIL );
		}
		else if( cmd == CMD_WAIT )
		{
			ASSERT( state == STATE_RX_ON || state == STATE_TRX_OFF || state == STATE_SLEEP );

			cmd = CMD_NONE;
			signal RadioWait.fired();
		}
	}

/*----------------- WAIT -----------------*/

	void cancelUserWait()
	{
		if( cmd == CMD_WAIT )
		{
			call Alarm.stop();
			atomic interrupts &= ~IRQ_ALARM;
			cmd = CMD_NONE;
		}
	}

	async command uint16_t RadioWait.getNow()
	{
		return call Alarm.getNow();
	}

	tasklet_async command void RadioWait.cancel()
	{
	}

	tasklet_async command error_t RadioWait.wait(uint16_t time)
	{
		if( cmd > CMD_WAIT )
			return EBUSY;
		else if( cmd == CMD_WAIT )
			call Alarm.stop();

		atomic interrupts &= ~IRQ_ALARM;
		call Alarm.start(time);
		cmd = CMD_WAIT;

		return SUCCESS;
	}

	default tasklet_async event void RadioWait.fired()
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

		return SUCCESS;
	}

	command error_t SoftwareInit.init()
	{
		return call SpiResource.request();
	}

	void initRadio()
	{
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("power on");
			call DiagMsg.send();
		}

		call BusyWait.wait(510);

		call RSTN.clr();
		call SLP_TR.clr();
		call BusyWait.wait(6);
		call RSTN.set();

		writeRegister(RF230_TRX_CTRL_0, RF230_TRX_CTRL_0_VALUE);
		writeRegister(RF230_TRX_STATE, RF230_TRX_OFF);

		call BusyWait.wait(510);

		writeRegister(RF230_IRQ_MASK, RF230_IRQ_TRX_UR | RF230_IRQ_PLL_UNLOCK | RF230_IRQ_PLL_LOCK | RF230_IRQ_TRX_END | RF230_IRQ_RX_START);
		writeRegister(RF230_CCA_THRES, RF230_CCA_THRES_VALUE);
		writeRegister(RF230_PHY_TX_PWR, RF230_TX_AUTO_CRC_ON | RF230_TX_PWR_DEFAULT);

		txPower = RF230_TX_PWR_DEFAULT;
		channel = call RF230Config.getDefaultChannel() & RF230_CHANNEL_MASK;
		writeRegister(RF230_PHY_CC_CCA, RF230_CCA_MODE_VALUE | channel);

//		writeRegister(RF230_XOSC_CTRL, RF230_XTAL_MODE_INTERNAL | 15);

		call SLP_TR.set();
		state = STATE_SLEEP;
	}

/*----------------- SPI -----------------*/

	event void SpiResource.granted()
	{
		// TODO: this should not be here, see my comment in HplRF230C.nc
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
			// TODO: this should not be here, see my comment in HplRF230C.nc
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

		if( cmd > CMD_WAIT )
			return EBUSY;
		else if( channel == c )
			return EALREADY;

		cancelUserWait();

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
			&& state == STATE_SLEEP )
		{
			call SLP_TR.clr();

			startAlarm(SLEEP_WAKEUP_TIME);
			state = STATE_SLEEP_2_TRX_OFF;
		}
		else if( cmd == CMD_TURNON && state == STATE_TRX_OFF && isSpiAcquired() )
		{
			call IRQ.captureRisingEdge();
			writeRegister(RF230_TRX_STATE, RF230_RX_ON);
			state = STATE_TRX_OFF_2_RX_ON;
		}
		else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() )
		{
			call IRQ.disable();
			writeRegister(RF230_TRX_STATE, RF230_FORCE_TRX_OFF);
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
		if( cmd > CMD_WAIT )
			return EBUSY;
		else if( state == STATE_SLEEP )
			return EALREADY;

		cancelUserWait();

		cmd = CMD_TURNOFF;
		call Tasklet.schedule();

		return SUCCESS;
	}
	
	tasklet_async command error_t RadioState.standby()
	{
		if( cmd > CMD_WAIT )
			return EBUSY;
		else if( state == STATE_TRX_OFF )
			return EALREADY;

		cancelUserWait();

		cmd = CMD_STANDBY;
		call Tasklet.schedule();

		return SUCCESS;
	}

	tasklet_async command error_t RadioState.turnOn()
	{
		if( cmd > CMD_WAIT )
			return EBUSY;
		else if( state == STATE_RX_ON )
			return EALREADY;

		cancelUserWait();

		cmd = CMD_TURNON;
		call Tasklet.schedule();

		return SUCCESS;
	}

	default tasklet_async event void RadioState.done()
	{
	}

/*----------------- TRANSMIT -----------------*/

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		uint16_t time;
		uint8_t length;
		uint8_t* data;

		if( cmd > CMD_WAIT || state != STATE_RX_ON || ! isSpiAcquired() )
			return EBUSY;

		length = call RF230Config.getTransmitPower(msg) & RF230_TX_PWR_MASK;
		if( length != txPower )
		{
			txPower = length;
			writeRegister(RF230_PHY_TX_PWR, RF230_TX_AUTO_CRC_ON | txPower);
		}

		writeRegister(RF230_TRX_STATE, RF230_PLL_ON);

		// wait a little for the command to complete
		length = call RF230Config.getLength(msg);
		data = call RF230Config.getPayload(msg);

		// maybe we are currently receiving a message
		if( (readRegister(RF230_TRX_STATUS) & RF230_TRX_STATUS_MASK) != RF230_PLL_ON )
		{
			writeRegister(RF230_TRX_STATE, RF230_RX_ON);
			return EBUSY;
		}

		cancelUserWait();

		if( call DiagMsg.record() )
		{
			call DiagMsg.str("tx");
			call DiagMsg.uint8(length);
			call DiagMsg.hex8s(data, length - 2);
			call DiagMsg.send();
		}

		atomic
		{
			call SLP_TR.set();
			time = call Alarm.getNow();
		}

		call SLP_TR.clr();

		// write the length first to buy some time
		call SELN.clr();
		call HplRF230.spiWrite(RF230_CMD_FRAME_WRITE);

		// length | data[0] ... data[length-3] | automatically generated FCS
		call HplRF230.spiWrite(length);

		// the FCF is atomatically generated
		length -= 2;

		do 
		{
			// TODO: we could do this faster with split access like for download
			call HplRF230.spiWrite(*(data++));
		}
		while( --length != 0 );

		call SELN.set();
		// wait for the TRX_END interrupt

		time += TX_SFD_DELAY;
		call RF230Config.setTimestamp(msg, time);

		// go back to RX_ON state when finished
		writeRegister(RF230_TRX_STATE, RF230_RX_ON);

		state = STATE_BUSY_TX_2_RX_ON;
		cmd = CMD_TRANSMIT;

		return SUCCESS;
	}

	default tasklet_async event void RadioSend.sendDone(error_t error)
	{
	}

/*----------------- CCA -----------------*/

	tasklet_async command error_t RadioCCA.request()
	{
		if( cmd > CMD_WAIT || state != STATE_RX_ON || ! isSpiAcquired() )
			return EBUSY;

		cancelUserWait();

		// see Errata B7 of the datasheet
		// writeRegister(RF230_TRX_STATE, RF230_PLL_ON);
		// writeRegister(RF230_TRX_STATE, RF230_RX_ON);

		writeRegister(RF230_PHY_CC_CCA, RF230_CCA_REQUEST | RF230_CCA_MODE_VALUE | channel);
		startAlarm(CCA_REQUEST_TIME);
		cmd = CMD_CCA;
		
		return SUCCESS;
	}

	default tasklet_async event void RadioCCA.done(error_t error)
	{
	}

/*----------------- RECEIVE -----------------*/

	tasklet_norace uint16_t rx_start_time;
	tasklet_norace uint16_t trx_end_time;

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

			while( read-- != 0 )
				crc = call HplRF230.crcByte(crc, *(data++) = call HplRF230.spiSplitReadWrite(0));

			if( signal RadioReceive.header(rxMsg) )
			{
				while( length-- != 0 )
					crc = call HplRF230.crcByte(crc, *(data++) = call HplRF230.spiSplitReadWrite(0));

				crc = call HplRF230.crcByte(crc, call HplRF230.spiSplitReadWrite(0));
				crc = call HplRF230.crcByte(crc, call HplRF230.spiSplitReadWrite(0));

				call RF230Config.setLinkQuality(rxMsg, call HplRF230.spiSplitRead());
			}
			else
				crc = 1;
		}
		else
			crc = 1;

		call SELN.set();
		state = STATE_RX_ON;

		if( call DiagMsg.record() )
		{
			length = call RF230Config.getLength(rxMsg);
			call DiagMsg.uint16(rx_start_time);
			call DiagMsg.uint16(trx_end_time);
			call DiagMsg.uint8(length);
			call DiagMsg.uint8(crc != 0);
			call DiagMsg.hex8s(call RF230Config.getPayload(rxMsg), length - 2);
			call DiagMsg.send();
		}

		cmd = CMD_NONE;

		// signal only if it has passed the CRC check
		if( crc == 0 )
			rxMsg = signal RadioReceive.receive(rxMsg);
	}

/*----------------- IRQ -----------------*/

	async event void IRQ.captured(uint16_t time)
	{
		ASSERT( ! (getInterrupts() & IRQ_RADIO) );

		atomic
		{
			capturedTime = time;
			interrupts |= IRQ_RADIO;
		}

		call Tasklet.schedule();
	}

	void serviceRadio()
	{
		if( isSpiAcquired() )
		{
			uint16_t time;
			uint8_t radioIrq;
			
			atomic time = capturedTime;
			radioIrq = readRegister(RF230_IRQ_STATUS);

			// TODO: handle this interrupt
			ASSERT( ! (radioIrq & RF230_IRQ_TRX_UR) );

			// TODO: handle this interrupt
			ASSERT( ! (radioIrq & RF230_IRQ_PLL_UNLOCK) );

			if( radioIrq & RF230_IRQ_PLL_LOCK )
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

			if( radioIrq & RF230_IRQ_RX_START )
			{
				if( cmd == CMD_CCA )
				{
					signal RadioCCA.done(FAIL);
					cmd = CMD_NONE;
				}

				if( cmd == CMD_NONE )
				{
					rx_start_time = time;

					/*
					 * The timestamp corresponds to the first event which could not
					 * have been a PLL_LOCK because then cmd != CMD_NONE, so we must
					 * have received a message (and could also have received the 
					 * TRX_END interrupt in the mean time, but that is fine. Also,
					 * we could not be after a transmission, because then cmd = 
					 * CMD_TRANSMIT.
					 */
					call RF230Config.setTimestamp(rxMsg, time - RX_SFD_DELAY);
					cmd = CMD_RECEIVE;
				}
			}

			if( radioIrq & RF230_IRQ_TRX_END )
			{
				if( cmd == CMD_TRANSMIT )
				{
					state = STATE_RX_ON;
					cmd = CMD_NONE;
					signal RadioSend.sendDone(SUCCESS);

					// TODO: we could have missed a received message
					ASSERT( ! (radioIrq & RF230_IRQ_RX_START) );
				}
				else if( cmd == CMD_RECEIVE )
				{
					trx_end_time = time;
					cmd = CMD_DOWNLOAD;
				}
				else
					ASSERT(FALSE);
			}
		}
		else
			atomic interrupts |= IRQ_RADIO;
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

	inline async command void RadioTasklet.schedule()
	{
		call Tasklet.schedule();
	}

	inline command void RadioTasklet.suspend()
	{
		call Tasklet.suspend();
	}

	inline command void RadioTasklet.resume()
	{
		call Tasklet.resume();
	}

	default tasklet_async event void RadioTasklet.run()
	{
	}

	tasklet_async event void Tasklet.run()
	{
		uint8_t irqs;

		atomic
		{
			irqs = interrupts;
			interrupts = 0;
		}

		if( irqs != 0 )
		{
			if( irqs & IRQ_RADIO )
				serviceRadio();
			else if( irqs & IRQ_ALARM )
				serviceAlarm();
		}

		if( cmd != CMD_NONE )
		{
			if( CMD_TURNOFF <= cmd && cmd <= CMD_TURNON )
				changeState();
			else if( cmd == CMD_CHANNEL )
				changeChannel();
			else if( cmd == CMD_DOWNLOAD )
				downloadMessage();
			
			if( cmd == CMD_SIGNAL_DONE )
			{
				cmd = CMD_NONE;
				signal RadioState.done();
			}
		}

		if( cmd == CMD_NONE )
			signal RadioTasklet.run();

		if( cmd == CMD_NONE )
			call SpiResource.release();
	}
}
