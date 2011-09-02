/*
 * Copyright (c) 2010, Vanderbilt University
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
 * Author: Janos Sallai
 */

#include <CC2420XDriverLayer.h>
#include <Tasklet.h>
#include <RadioAssert.h>
#include <TimeSyncMessageLayer.h>
#include <RadioConfig.h>
#define spi_atomic
module CC2420XDriverLayerP
{
	provides
	{
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
		interface Resource as SpiResource;
		interface BusyWait<TMicro, uint16_t>;
		interface LocalTime<TRadio>;
		interface CC2420XDriverConfig as Config;

		interface FastSpiByte;
		interface GeneralIO as CSN;
		interface GeneralIO as VREN;
		interface GeneralIO as CCA;
		interface GeneralIO as RSTN;
		interface GeneralIO as FIFO;
		interface GeneralIO as FIFOP;
		interface GeneralIO as SFD;
		interface GpioCapture as SfdCapture;
		interface GpioInterrupt as FifopInterrupt;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;

		interface PacketTimeStamp<TRadio, uint32_t>;

		interface Tasklet;
		interface RadioAlarm;

#ifdef RADIO_DEBUG
		interface DiagMsg;
#endif
		interface Leds;
	}
}

implementation
{
	cc2420x_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call Config.headerLength(msg);
	}

	void* getPayload(message_t* msg)
	{
		return ((void*)msg);
	}

	cc2420x_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

/*----------------- STATE -----------------*/

	enum
	{
		STATE_VR_ON = 0,
		STATE_PD = 1,
		STATE_PD_2_IDLE = 2,
		STATE_IDLE = 3,
		STATE_IDLE_2_RX_ON = 4,
		STATE_RX_ON = 5,
		STATE_BUSY_TX_2_RX_ON = 6,
		STATE_IDLE_2_TX_ON = 7,
		STATE_TX_ON = 8,
		STATE_RX_DOWNLOAD = 9,
	};
	norace uint8_t state = STATE_VR_ON;

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
	tasklet_norace uint8_t cmd = CMD_NONE;

	norace bool radioIrq = 0;

	tasklet_norace uint8_t txPower;
	tasklet_norace uint8_t channel;

	tasklet_norace message_t* rxMsg;
#ifdef RADIO_DEBUG_MESSAGES	
	tasklet_norace message_t* txMsg;
#endif	
	message_t rxMsgBuffer;

	uint16_t capturedTime;	// time when the last SFD interrupt has occured

	inline cc2420X_status_t getStatus();

/*----------------- ALARM -----------------*/
	tasklet_async event void RadioAlarm.fired()
	{		
		if( state == STATE_PD_2_IDLE ) {
			state = STATE_IDLE;
			if( cmd == CMD_STANDBY )
				cmd = CMD_SIGNAL_DONE;
		}
		else if( state == STATE_IDLE_2_RX_ON ) {
			state = STATE_RX_ON;
			cmd = CMD_SIGNAL_DONE;
			// in receive mode, enable SFD capture
      			call SfdCapture.captureRisingEdge();	
		}
		else
			RADIO_ASSERT(FALSE);

		// make sure the rest of the command processing is called
		call Tasklet.schedule();
	}

/*----------------- REGISTER -----------------*/

	inline uint16_t readRegister(uint8_t reg)
	{		
		uint16_t value = 0;
		
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & CC2420X_CMD_REGISTER_MASK) );

		call CSN.set();
		call CSN.clr();
		
		call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_READ | reg);
		call FastSpiByte.splitReadWrite(0);
		value = ((uint16_t)call FastSpiByte.splitReadWrite(0) << 8);
		value += call FastSpiByte.splitRead();
		call CSN.set();

		return value;
	}

	inline cc2420X_status_t strobe(uint8_t reg)
	{
		cc2420X_status_t status;
		
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & CC2420X_CMD_REGISTER_MASK) );

		call CSN.set();
		call CSN.clr();

		call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_WRITE | reg);
		status.value = call FastSpiByte.splitRead();

		call CSN.set();
		return status;
		
	}

	inline cc2420X_status_t getStatus() {
		return strobe(CC2420X_SNOP);
	}

	inline cc2420X_status_t writeRegister(uint8_t reg, uint16_t value)
	{
		cc2420X_status_t status;
		
		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( reg == (reg & CC2420X_CMD_REGISTER_MASK) );

		call CSN.set();
		call CSN.clr();

		call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_WRITE | reg);
		call FastSpiByte.splitReadWrite(value >> 8);
		call FastSpiByte.splitReadWrite(value & 0xff);
		status.value = call FastSpiByte.splitRead();

		call CSN.set();
		return status;		
	}

	inline cc2420X_status_t writeTxFifo(uint8_t* data, uint8_t length)
	{
		cc2420X_status_t status;
		uint8_t idx;
		
		RADIO_ASSERT( call SpiResource.isOwner() );

		call CSN.set();
		call CSN.clr();

		call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_WRITE | CC2420X_TXFIFO);
		for(idx = 0; idx<length; idx++)
			call FastSpiByte.splitReadWrite(data[idx]);
		status.value = call FastSpiByte.splitRead();

		call CSN.set();
		return status;		
	}

	inline uint8_t waitForRxFifoNoTimeout() {
		// spin until fifo goes high
		while(call FIFO.get() == 0);
		
		return call FIFO.get();
	}

	inline uint8_t waitForRxFifo() {

		// wait for fifo to go high or timeout
		// timeout is now + 2 byte time (4 symbol time)
		uint16_t timeout = call RadioAlarm.getNow() + 4 * CC2420X_SYMBOL_TIME;
			
		while(call FIFO.get() == 0 && (timeout - call RadioAlarm.getNow() < 0x7fff));
		return call FIFO.get();
	}

	inline cc2420X_status_t readLengthFromRxFifo(uint8_t* lengthPtr)
	{
		cc2420X_status_t status;

		RADIO_ASSERT( call SpiResource.isOwner() );
		RADIO_ASSERT( call CSN.get() == 1 );


		call CSN.set();	// set CSN, just in clase it's not set
		call CSN.clr(); // clear CSN, starting a multi-byte SPI command

		// wait for fifo to go high
		waitForRxFifoNoTimeout();
		
		// issue SPI command
		call FastSpiByte.splitWrite(CC2420X_CMD_REGISTER_READ | CC2420X_RXFIFO);
		status.value = call FastSpiByte.splitRead();
		call FastSpiByte.splitWrite(0);
		
		*lengthPtr = call FastSpiByte.splitRead();
		
		// start reading the next byte
		// important! fifo pin must be checked after the previous SPI read completed
		waitForRxFifo();
		call FastSpiByte.splitWrite(0);
		return status;		
	}

	inline void readPayloadFromRxFifo(uint8_t* data, uint8_t length)
	{
		uint8_t idx;
		
		// readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
		RADIO_ASSERT( call CSN.get() == 0 );


		for(idx = 0; idx<length; idx++) {
			data[idx] = call FastSpiByte.splitRead();
			waitForRxFifo();
			call FastSpiByte.splitWrite(0);
		}
	}
	
	inline void readRssiFromRxFifo(uint8_t* rssiPtr)
	{
		// readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
		RADIO_ASSERT( call CSN.get() == 0 );

		*rssiPtr = call FastSpiByte.splitRead();
		waitForRxFifo();
		call FastSpiByte.splitWrite(0);
	}
	
	inline void readCrcOkAndLqiFromRxFifo(uint8_t* crcOkAndLqiPtr)
	{
		// readLengthFromRxFifo was called before, so CSN is cleared and spi is ours
		RADIO_ASSERT( call CSN.get() == 0 );
		
		*crcOkAndLqiPtr = call FastSpiByte.splitRead();	
		
		// end RxFifo read operation
		call CSN.set();
	}

	inline void flushRxFifo() {
		// make sure that at least one byte has been read 
		// from the rx fifo before calling this function
		strobe(CC2420X_SFLUSHRX);
		strobe(CC2420X_SFLUSHRX);
	}
	
/*----------------- INIT -----------------*/

	command error_t SoftwareInit.init()
	{
		// set pin directions
    		call CSN.makeOutput();
    		call VREN.makeOutput(); 		
    		call RSTN.makeOutput(); 		
    		call CCA.makeInput();
    		call SFD.makeInput();
    		call FIFO.makeInput();
    		call FIFOP.makeInput();    		

		call FifopInterrupt.disable();
		call SfdCapture.disable();

		// CSN is active low		
    		call CSN.set();

		// start up voltage regulator
    		call VREN.set();
    		call BusyWait.wait( 600 ); // .6ms VR startup time
    		
    		// do a reset
		call RSTN.clr();
		call RSTN.set();
    
		rxMsg = &rxMsgBuffer;

		state = STATE_VR_ON;

		// request SPI, rest of the initialization will be done from
		// the granted event
		return call SpiResource.request();
	}

	inline void resetRadio() {
		
		cc2420X_iocfg0_t iocfg0;
		cc2420X_mdmctrl0_t mdmctrl0;

    		// do a reset
		call RSTN.clr();
		call RSTN.set();

		// set up fifop polarity and threshold
		iocfg0 = cc2420X_iocfg0_default;
		iocfg0.f.fifop_thr = 127;
      		writeRegister(CC2420X_IOCFG0, iocfg0.value);
		      
		// set up modem control
		mdmctrl0 = cc2420X_mdmctrl0_default;
		mdmctrl0.f.reserved_frame_mode = 1; //accept reserved frames
		mdmctrl0.f.adr_decode = 0; // disable
      		writeRegister(CC2420X_MDMCTRL0, mdmctrl0.value);		

		state = STATE_PD;
	}


	void initRadio()
	{
		resetRadio();		
		
		txPower = CC2420X_DEF_RFPOWER & CC2420X_TX_PWR_MASK;
		channel = CC2420X_DEF_CHANNEL & CC2420X_CHANNEL_MASK;		

	}

/*----------------- SPI -----------------*/

	event void SpiResource.granted()
	{
		
		call CSN.makeOutput();
		call CSN.set();

		if( state == STATE_VR_ON )
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
			call CSN.makeOutput();
			call CSN.set();

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
		c &= CC2420X_CHANNEL_MASK;

		if( cmd != CMD_NONE )
			return EBUSY;
		else if( channel == c )
			return EALREADY;

		channel = c;
		cmd = CMD_CHANNEL;
		call Tasklet.schedule();

		return SUCCESS;
	}

	inline void setChannel()
	{
		cc2420X_fsctrl_t fsctrl;
		// set up freq
		fsctrl= cc2420X_fsctrl_default;
		fsctrl.f.freq = 357+5*(channel - 11);
		
      		writeRegister(CC2420X_FSCTRL, fsctrl.value);
	}

	inline void changeChannel()
	{
		RADIO_ASSERT( cmd == CMD_CHANNEL );
		RADIO_ASSERT( state == STATE_PD || state == STATE_IDLE || ( state == STATE_RX_ON && call RadioAlarm.isFree()));

		if( isSpiAcquired() )
		{
			setChannel();

			if( state == STATE_RX_ON ) {
				call RadioAlarm.wait(IDLE_2_RX_ON_TIME); // 12 symbol periods
				state = STATE_IDLE_2_RX_ON;				
			}
			else
				cmd = CMD_SIGNAL_DONE;
		}
	}

/*----------------- TURN ON/OFF -----------------*/

	inline void changeState()
	{

		if( (cmd == CMD_STANDBY || cmd == CMD_TURNON)
			&& state == STATE_PD  && isSpiAcquired() && call RadioAlarm.isFree() )
		{
			// start oscillator
      			strobe(CC2420X_SXOSCON); 

			call RadioAlarm.wait(PD_2_IDLE_TIME); // .86ms OSC startup time
			state = STATE_PD_2_IDLE;
		}
		else if( cmd == CMD_TURNON && state == STATE_IDLE && isSpiAcquired() && call RadioAlarm.isFree())
		{
			// setChannel was ignored in SLEEP because the SPI was not working, so do it here
			setChannel();

			// start receiving
      			strobe(CC2420X_SRXON); 
			call RadioAlarm.wait(IDLE_2_RX_ON_TIME); // 12 symbol periods      			
			state = STATE_IDLE_2_RX_ON;
		}
		else if( (cmd == CMD_TURNOFF || cmd == CMD_STANDBY) 
			&& state == STATE_RX_ON && isSpiAcquired() )
		{
			// disable SFD capture
      			call SfdCapture.disable();	

			// stop receiving
      			strobe(CC2420X_SRFOFF); 			
			state = STATE_IDLE;
		}

		if( cmd == CMD_TURNOFF && state == STATE_IDLE  && isSpiAcquired() )
		{
      			// stop oscillator
      			strobe(CC2420X_SXOSCOFF); 

			// do a reset
			initRadio();
			state = STATE_PD;
			cmd = CMD_SIGNAL_DONE;
		}
		else if( cmd == CMD_STANDBY && state == STATE_IDLE )
			cmd = CMD_SIGNAL_DONE;
	}

	tasklet_async command error_t RadioState.turnOff()
	{
		if( cmd != CMD_NONE )
			return EBUSY;
		else if( state == STATE_PD )
			return EALREADY;

#ifdef RADIO_DEBUG_STATE
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("turnOff");
			call DiagMsg.uint16(call RadioAlarm.getNow());			
			call DiagMsg.send();
		}
#endif

		cmd = CMD_TURNOFF;
		call Tasklet.schedule();

		return SUCCESS;
	}
	
	tasklet_async command error_t RadioState.standby()
	{
		if( cmd != CMD_NONE || (state == STATE_PD && ! call RadioAlarm.isFree()) )
			return EBUSY;
		else if( state == STATE_IDLE )
			return EALREADY;

#ifdef RADIO_DEBUG_STATE
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("standBy");
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.send();
		}
#endif

		cmd = CMD_STANDBY;
		call Tasklet.schedule();

		return SUCCESS;
	}

	// TODO: turn on SFD capture when turning off radio
	tasklet_async command error_t RadioState.turnOn()
	{
		if( cmd != CMD_NONE || (state == STATE_PD && ! call RadioAlarm.isFree()) )
			return EBUSY;
		else if( state == STATE_RX_ON )
			return EALREADY;

#ifdef RADIO_DEBUG_STATE
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("turnOn");
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.send();
		}
#endif

		cmd = CMD_TURNON;
		call Tasklet.schedule();

		return SUCCESS;
	}

	default tasklet_async event void RadioState.done() { }

/*----------------- TRANSMIT -----------------*/

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		uint16_t time;
		uint8_t p;
		uint8_t length;
		uint8_t* data;
		uint8_t header;
		uint32_t time32;
		void* timesync;
		timesync_relative_t timesync_relative;
		uint32_t sfdTime;

		if( cmd != CMD_NONE || (state != STATE_IDLE && state != STATE_RX_ON) || ! isSpiAcquired() || radioIrq )
			return EBUSY;

		p = (call PacketTransmitPower.isSet(msg) ?
			call PacketTransmitPower.get(msg) : CC2420X_DEF_RFPOWER) & CC2420X_TX_PWR_MASK;

		if( p != txPower )
		{
			cc2420X_txctrl_t txctrl = cc2420X_txctrl_default;

			txPower = p;

			txctrl.f.pa_level = txPower;
			writeRegister(CC2420X_TXCTRL, txctrl.value);
		}

		if( call Config.requiresRssiCca(msg) && !call CCA.get() )
			return EBUSY;
			
		data = getPayload(msg);
		length = getHeader(msg)->length;
		
		// length | data[0] ... data[length-3] | automatically generated FCS

		header = call Config.headerPreloadLength();
		if( header > length )
			header = length;

		length -= header;

		// disable SFD interrupt
		call SfdCapture.disable();

		// first upload the header to gain some time
		spi_atomic writeTxFifo(data, header);

		// there's a chance that there was a receive SFD interrupt in such a short time
		// we probably didn't cover all possibilities, but that's OK: downloadMessage() can 
		// clean up the RXFIFO if necessary
		if( cmd != CMD_NONE || (state != STATE_IDLE && state != STATE_RX_ON) || radioIrq || call SFD.get() == 1 ) {
			// discard header we wrote to TXFIFO
			strobe(CC2420X_SFLUSHTX);
			// re-enable SFD interrupt
			call SfdCapture.captureRisingEdge();
			// and bail out
			return EBUSY;
		}

		// there's _still_ a chance that there was a receive SFD interrupt in such a short
		// time , but that's OK: downloadMessage() can clean up the RXFIFO if necessary
		
		atomic {
			// zero out capturedTime
			// the SFD interrupt will set it again _while_ this function is running
			capturedTime = 0;

			// start transmission
			strobe(CC2420X_STXON);
			
			// get a timestamp right after strobe returns
			time = call RadioAlarm.getNow();

			cmd = CMD_TRANSMIT;			
			state = STATE_TX_ON;
			call SfdCapture.captureFallingEdge();
		}

		timesync = call PacketTimeSyncOffset.isSet(msg) ? ((void*)msg) + call PacketTimeSyncOffset.get(msg) : 0;

		if( timesync == 0 ) {
			// no timesync: write the entire payload to the fifo
			if(length>0)
				spi_atomic writeTxFifo(data+header, length - 1);
			state = STATE_BUSY_TX_2_RX_ON;
		} else {
			// timesync required: write the payload before the timesync bytes to the fifo
			// TODO: we're assuming here that the timestamp is at the end of the message
			spi_atomic writeTxFifo(data+header, length - sizeof(timesync_relative) - 1);
		}
		
		
		// compute timesync
		sfdTime = time;
		
		// read both clocks
		// TODO: how can atomic be removed???
		atomic {
			time = call RadioAlarm.getNow();
			time32 = call LocalTime.get();
		}
			
		// adjust time32 with the time elapsed since the SFD event
		time -= sfdTime;
		time32 -= time;

		// adjust for delay between the STXON strobe and the transmission of the SFD
		time32 += TX_SFD_DELAY;

                call PacketTimeStamp.set(msg, time32);
                
		if( timesync != 0 ) {
			// read and adjust the timestamp field
			timesync_relative = (*(timesync_absolute_t*)timesync) - time32;

			// write it to the fifo
			// TODO: we're assuming here that the timestamp is at the end of the message			
			spi_atomic writeTxFifo((uint8_t*)(&timesync_relative), sizeof(timesync_relative));
			state = STATE_BUSY_TX_2_RX_ON;
		}

#ifdef RADIO_DEBUG_MESSAGES
		txMsg = msg;
		
		if( call DiagMsg.record() )
		{
			length = getHeader(msg)->length;

			call DiagMsg.chr('t');
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.uint32(call PacketTimeStamp.isValid(msg) ? call PacketTimeStamp.timestamp(msg) : 0);
			call DiagMsg.int8(length);
			call DiagMsg.hex8s(getPayload(msg), length);
			call DiagMsg.send();
		}
#endif

		return SUCCESS;
	}

	default tasklet_async event void RadioSend.sendDone(error_t error) { }
	default tasklet_async event void RadioSend.ready() { }

/*----------------- CCA -----------------*/

	tasklet_async command error_t RadioCCA.request()
	{
		if( cmd != CMD_NONE || state != STATE_RX_ON )
			return EBUSY;

		if(call CCA.get()) {
			signal RadioCCA.done(SUCCESS);		
		} else {
			signal RadioCCA.done(EBUSY);		
		}
		return SUCCESS;
	}

	default tasklet_async event void RadioCCA.done(error_t error) { }

/*----------------- RECEIVE -----------------*/

	// recover from an error
	// rx fifo flush does not always work
	inline void recover() {
		cc2420X_status_t status;
		
		call SfdCapture.disable();	

		// reset the radio, initialize registers to default values
		resetRadio();
		
		RADIO_ASSERT(state == STATE_PD);		
		
		// start oscillator
      		strobe(CC2420X_SXOSCON); 
      		
      		// going idle in PD_2_IDLE_TIME
      		state = STATE_PD_2_IDLE;
      		
		call BusyWait.wait(PD_2_IDLE_TIME); // .86ms OSC startup time

		// get status
		status = getStatus();
		RADIO_ASSERT(status.rssi_valid == 0);
		RADIO_ASSERT(status.lock == 0);
		RADIO_ASSERT(status.tx_active == 0);
		RADIO_ASSERT(status.enc_busy == 0);
		RADIO_ASSERT(status.tx_underflow == 0);
		RADIO_ASSERT(status.xosc16m_stable == 1);
		
		// we're idle now	
		state = STATE_IDLE;		
		
		// download current channel to the radio
		setChannel();

      		// start receiving
      		strobe(CC2420X_SRXON); 
      		state = STATE_IDLE_2_RX_ON;		
      		
		call SfdCapture.captureRisingEdge();	
      		
		// we will be able to receive packets in 12 symbol periods  
		state = STATE_RX_ON;		
	}

	inline void downloadMessage()
	{
		uint8_t length;
		uint16_t crc = 1;
		uint8_t* data;
		uint8_t rssi;
		uint8_t crc_ok_lqi;
		uint16_t sfdTime;
				
						
		state = STATE_RX_DOWNLOAD;
		
		atomic sfdTime = capturedTime;
		
		// data starts after the length field
		data = getPayload(rxMsg) + sizeof(cc2420x_header_t);

		// read the length byte
		spi_atomic readLengthFromRxFifo(&length);

		// check for too short lengths
		if (length == 0) {
			// stop reading RXFIFO
			call CSN.set();

			RADIO_ASSERT( call FIFOP.get() == 0 );
			RADIO_ASSERT( call FIFO.get() == 0 );
						
			state = STATE_RX_ON;
			cmd = CMD_NONE;
			call SfdCapture.captureRisingEdge();			
			return;
		}
		
		if (length == 1) {
			// skip payload and rssi
			spi_atomic readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);	

			RADIO_ASSERT( call FIFOP.get() == 0 );
			RADIO_ASSERT( call FIFO.get() == 0 );
			
			state = STATE_RX_ON;
			cmd = CMD_NONE;
			call SfdCapture.captureRisingEdge();			
			return;
		}

		if (length == 2) {
			// skip payload
			spi_atomic {
			  readRssiFromRxFifo(&rssi);
			  readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);	
			}
			
			RADIO_ASSERT( call FIFOP.get() == 0 );
			RADIO_ASSERT( call FIFO.get() == 0 );
			
			state = STATE_RX_ON;
			cmd = CMD_NONE;
			call SfdCapture.captureRisingEdge();			
			return;	
		}

		// check for too long lengths		
		if( length > 127 ) {
			
			recover();

			RADIO_ASSERT( call FIFOP.get() == 0 );
			RADIO_ASSERT( call FIFO.get() == 0 );
			
			state = STATE_RX_ON;
			cmd = CMD_NONE;
			call SfdCapture.captureRisingEdge();			
			return;	
		}
		
		if( length > call RadioPacket.maxPayloadLength() + 2 )
		{
			while( length-- > 2 ) {
				readPayloadFromRxFifo(data, 1);
			}

			spi_atomic {
			  readRssiFromRxFifo(&rssi);
			  readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);	
			}
			
			RADIO_ASSERT( call FIFOP.get() == 0 );
			
			state = STATE_RX_ON;
			cmd = CMD_NONE;
			call SfdCapture.captureRisingEdge();			
			return;	
		}

		// if we're here, length must be correct
		RADIO_ASSERT(length >= 3 && length <= call RadioPacket.maxPayloadLength() + 2);

		getHeader(rxMsg)->length = length;

		// we'll read the FCS/CRC separately
		length -= 2;		

		spi_atomic {
		// download the whole payload
		readPayloadFromRxFifo(data, length );

		// the last two bytes are not the fsc, but RSSI(8), CRC_ON(1)+LQI(7)
		readRssiFromRxFifo(&rssi);
		readCrcOkAndLqiFromRxFifo(&crc_ok_lqi);
		}
		
		// there are still bytes in the fifo or if there's an overflow, recover
		// TODO: actually, we can signal that a message was received, without timestamp set
		if (call FIFOP.get() == 1 || call FIFO.get() == 1) {
			recover();
			state = STATE_RX_ON;
			cmd = CMD_NONE;
			call SfdCapture.captureRisingEdge();			
			return;
		}
		
		state = STATE_RX_ON;
		cmd = CMD_NONE;

		// ready to receive new message: enable SFD interrupts
		call SfdCapture.captureRisingEdge();
		
		if( signal RadioReceive.header(rxMsg) )
		{
			// set RSSI, CRC and LQI only if we're accepting the message
			call PacketRSSI.set(rxMsg, rssi);
			call PacketLinkQuality.set(rxMsg, crc_ok_lqi & 0x7f);
			crc = (crc_ok_lqi > 0x7f) ? 0 : 1;
		}
			
		// signal only if it has passed the CRC check
		if( crc == 0 ) {
			uint32_t time32;
			uint16_t time;
			atomic {
				time = call RadioAlarm.getNow();
				time32 = call LocalTime.get();
			}

				
			time -= sfdTime;
			time32 -= time;

			call PacketTimeStamp.set(rxMsg, time32);

			
#ifdef RADIO_DEBUG_MESSAGES
			if( call DiagMsg.record() )
			{
				call DiagMsg.str("r");
				call DiagMsg.uint16(call RadioAlarm.getNow() - (uint16_t)call PacketTimeStamp.timestamp(rxMsg) );
				call DiagMsg.uint16(call RadioAlarm.getNow());
				call DiagMsg.uint16(call PacketTimeStamp.isValid(rxMsg) ? call PacketTimeStamp.timestamp(rxMsg) : 0);
				call DiagMsg.int8(length);
				call DiagMsg.hex8s(getPayload(rxMsg), length);				
				call DiagMsg.send();
			}
#endif			
			rxMsg = signal RadioReceive.receive(rxMsg);

		}
						
	}


/*----------------- IRQ -----------------*/
	
	// RX SFD (rising edge), disabled for TX
	async event void SfdCapture.captured( uint16_t time )
	{

#ifdef RADIO_DEBUG_IRQ
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("SFD");
			call DiagMsg.uint16(call RadioAlarm.getNow());
			call DiagMsg.str("s=");
			call DiagMsg.uint8(state);
			if(call FIFO.get())
				call DiagMsg.str("FIFO");
			if(call FIFOP.get())
				call DiagMsg.str("FIFOP");
			if(call SFD.get())
				call DiagMsg.str("SFD");
					
			call DiagMsg.send();
		}
#endif


		RADIO_ASSERT( ! radioIrq );
		RADIO_ASSERT(state == STATE_RX_ON || state == STATE_TX_ON || state == STATE_BUSY_TX_2_RX_ON);

		atomic capturedTime = time;
		
		radioIrq = TRUE;
		call SfdCapture.disable();


		// do the rest of the processing
		call Tasklet.schedule();
	}

	// FIFOP interrupt, last byte received
	async event void FifopInterrupt.fired()
	{		
		// not used
	}

	inline void serviceRadio()
	{
		atomic if( isSpiAcquired() )
		{
			radioIrq = FALSE;

			if( state == STATE_RX_ON && cmd == CMD_NONE )
			{
				// it's an RX SFD
				cmd = CMD_DOWNLOAD;
			}
			else if( (state == STATE_TX_ON || state == STATE_BUSY_TX_2_RX_ON) && cmd == CMD_TRANSMIT)
			{
				cc2420X_status_t status;
				
				// it's a TX_END
				state = STATE_RX_ON;
				cmd = CMD_NONE;
#if defined(RADIO_DEBUG_IRQ) && defined(RADIO_DEBUG_MESSAGES)
			if( call DiagMsg.record() )
			{
				call DiagMsg.str("txdone");
				call DiagMsg.uint16(call RadioAlarm.getNow());
				call DiagMsg.uint16(capturedTime - (uint16_t)call PacketTimeStamp.timestamp(txMsg));
				if(call FIFO.get())
					call DiagMsg.str("FIFO");
				if(call FIFOP.get())
					call DiagMsg.str("FIFOP");
				if(call SFD.get())
					call DiagMsg.str("SFD");
					
				call DiagMsg.send();
			}
#endif
				
				call SfdCapture.captureRisingEdge();

				// get status
				status = getStatus();

				if ( status.tx_underflow == 1) {
					// flush tx fifo
					strobe(CC2420X_SFLUSHTX);
					signal RadioSend.sendDone(FAIL);
				} else {
					signal RadioSend.sendDone(SUCCESS);
				}
	
			}
			
			else
				RADIO_ASSERT(FALSE);
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
#ifdef RADIO_DEBUG_TASKLET
		if( call DiagMsg.record() )
		{
			call DiagMsg.str("tsk_str");
			call DiagMsg.uint16(call RadioAlarm.getNow());	
			call DiagMsg.str("s=");
			call DiagMsg.uint8(state);
			call DiagMsg.str("c=");
			call DiagMsg.uint8(cmd);
			if(radioIrq)
				call DiagMsg.str("IRQ");
			if(call FIFO.get())
				call DiagMsg.str("FIFO");
			if(call FIFOP.get())
				call DiagMsg.str("FIFOP");
			if(call SFD.get())
				call DiagMsg.str("SFD");
					
			call DiagMsg.send();
		}
#endif

		if( radioIrq )
			serviceRadio();

		if( cmd != CMD_NONE )
		{
			if( cmd == CMD_DOWNLOAD && state == STATE_RX_ON)
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
			
#ifdef RADIO_DEBUG_TASKLET
		if( call DiagMsg.record() )
		{
			call DiagMsg.uint16(call RadioAlarm.getNow());	
			call DiagMsg.str("tsk_end");
			call DiagMsg.str("s=");
			call DiagMsg.uint8(state);
			call DiagMsg.str("c=");
			call DiagMsg.uint8(cmd);
			if(radioIrq)
				call DiagMsg.str("IRQ");
			if(call FIFO.get())
				call DiagMsg.str("FIFO");
			if(call FIFOP.get())
				call DiagMsg.str("FIFOP");
			if(call SFD.get())
				call DiagMsg.str("SFD");
					
			call DiagMsg.send();
		}
#endif
	}

/*----------------- RadioPacket -----------------*/
	
	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call Config.headerLength(msg) + sizeof(cc2420x_header_t);
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
		RADIO_ASSERT( call Config.maxPayloadLength() - sizeof(cc2420x_header_t) <= 125 );

		return call Config.maxPayloadLength() - sizeof(cc2420x_header_t);
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call Config.metadataLength(msg) + sizeof(cc2420x_metadata_t);
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
		return call PacketLinkQuality.get(msg) > 105;
	}
}
