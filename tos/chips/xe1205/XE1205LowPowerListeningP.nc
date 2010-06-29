/* Copyright (c) 2007 Shockfish SA
 *  All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * @author Maxime Muller
 *
 */

#include "XE1205LowPowerListening.h"

module XE1205LowPowerListeningP {
    provides {
	interface Init;
	interface SplitControl;
	interface Send;
	interface Receive;
	interface LowPowerListening;

    }
    uses {
	interface LPLControl;
	interface SplitControl as SubControl;	
	interface CsmaControl;
	interface Send as SubSend;
	interface Receive as SubReceive;
	interface AMPacket;
	interface PacketAcknowledgements;
	interface Timer<TMilli> as SendTimeout;
	interface Timer<TMilli> as OnTimer;
	interface Timer<TMilli> as OffTimer;
	interface Random;
    }
}

implementation {

    message_t * curTxMsg;
    uint8_t curTxMsgLength;
    uint8_t seqNo;
    uint8_t lastSeqNo;
    uint8_t txSeqNo;
    uint16_t sleepInterval;
    uint16_t sleepTime;
    bool fromSplitStart = FALSE;
    bool fromSplitStop = FALSE;

    typedef enum {
	RADIO_INIT,
	RADIO_ON,
	RADIO_OFF,
	RADIO_TX,
    } lpl_state_t;
    
    lpl_state_t rState;
    
    
    void sendDone(error_t err);

    xe1205_header_t* getHeader( message_t* msg ) {
	return (xe1205_header_t*)( msg->data - sizeof(xe1205_header_t) );
    }
    
    xe1205_footer_t* getFooter(message_t* msg) {
	return (xe1205_footer_t*)(msg->footer);
    }
    command error_t Init.init() {
	sleepTime = DEFAULT_DUTY_PERIOD;
	atomic rState = RADIO_INIT;
	txSeqNo = call Random.rand16()&0xFE;
	return SUCCESS;
    }

    command error_t SplitControl.start() {
	// start dutyCycling
	if (rState == RADIO_OFF || rState == RADIO_INIT) {
	    if (SUCCESS==call SubControl.start()) {
		fromSplitStart = TRUE;
		return SUCCESS;
	    }
	} 
	return FAIL; 
    }
    
    event void SubControl.startDone(error_t err) {
	
	if(err==SUCCESS) {
	    if(sleepTime > 0) {// keep radio on for a while
		call OffTimer.stop();
		call OnTimer.startOneShot(DELAY_AFTER_RECEIVE);
	    }
	    if (sleepTime == 0) // radio always on
		call LPLControl.setMode(IDLE); 
	    atomic rState = RADIO_ON;

	    if (fromSplitStart) {
		fromSplitStart=FALSE;
		signal SplitControl.startDone(err);
	    }
	}
	else {
	    call SubControl.start();
	}
    }

    command error_t SplitControl.stop() {
	fromSplitStop = TRUE;
	
	return call SubControl.stop();
    }

    event void SubControl.stopDone(error_t err) {
	if(!err) {
	    if (rState == RADIO_ON) { 
		if (call OnTimer.isRunning()) {
		    call OnTimer.stop();
		}
	    }
	    atomic rState = RADIO_OFF;
	    if (fromSplitStop==FALSE) {
		call OffTimer.startOneShot(sleepTime);
	    } else {
		fromSplitStop = FALSE;
		signal SplitControl.startDone(err);
	    }
	} else
	    call OffTimer.startOneShot(sleepTime);
    }

    event void OffTimer.fired() { 
	if (SUCCESS==call SubControl.start()) {
	    if (sleepTime > 0)
		call LPLControl.setMode(RX);
	    if (sleepTime == 0) // radio always on
		call LPLControl.setMode(IDLE); 
	} 
	else 
	    call OffTimer.startOneShot(sleepTime);
    }

    event void OnTimer.fired() {
	// switch off the radio
	if(sleepTime > 0)
	    if (SUCCESS != call SubControl.stop()) {
		// retry
		call OnTimer.startOneShot(DELAY_AFTER_RECEIVE);
	    }
    }

    task void sendPkt() {
	if(SUCCESS != call SubSend.send(curTxMsg,curTxMsgLength)) {
	    call LPLControl.setMode(IDLE); 
	    call OffTimer.startOneShot(sleepTime);
	    sendDone(FAIL);
	}
    }

    /*
     * send commands
     */
    command error_t Send.send(message_t *msg, uint8_t len) {	
	if (rState == RADIO_INIT) return EOFF;
	
	else {
	    call OffTimer.stop();
	    call OnTimer.stop();
	    atomic rState = RADIO_TX;
	    curTxMsg = msg;
	    curTxMsgLength = len;
	    if(call LowPowerListening.getRxSleepInterval(curTxMsg) 
	       > ONE_MESSAGE) {
		txSeqNo+=0x02;
		if (AM_BROADCAST_ADDR != call AMPacket.destination(curTxMsg)) {
		    getHeader(curTxMsg)->ack = txSeqNo|0x01;
		} else
		    getHeader(curTxMsg)->ack = txSeqNo&0xFE;
		call CsmaControl.enableCca();
		
		if(SUCCESS==post sendPkt()) {
		    call SendTimeout.startOneShot(call LowPowerListening.getRxSleepInterval(curTxMsg) * 2);
		    return SUCCESS;
		}
		else {
		    call SendTimeout.stop();
		    call LPLControl.setMode(IDLE);
		    call OffTimer.startOneShot(sleepTime);
		    return FAIL;
		}
	    } else {
		call LPLControl.setMode(IDLE);
		call OffTimer.startOneShot(sleepTime);
		return FAIL;
	    }
	}
    }

    event void SendTimeout.fired() {
	atomic {
	    if (rState == RADIO_TX) // let sendDone occur
		rState = RADIO_ON;
	}
	call OffTimer.startOneShot(DELAY_AFTER_RECEIVE);
    }
	
    void sendDone(error_t err) {
	atomic {
	    if (rState == RADIO_TX)
		rState = RADIO_ON;
	}
	if(err!=FAIL) 
	    call SubControl.stop();
	signal Send.sendDone(curTxMsg, err);
    }

    event void SubSend.sendDone(message_t *msg, error_t err) {

	if(rState == RADIO_TX
	   && call SendTimeout.isRunning()) {
	    if ( AM_BROADCAST_ADDR != call AMPacket.destination(msg)
		 && err==SUCCESS) {
		call SendTimeout.stop();
		sendDone(err);
	    } else { // ack timeout or bcast msg
		call CsmaControl.disableCca();
		if(SUCCESS!=post sendPkt()) {

		    sendDone(FAIL);
		}
	    }
	} 
	else {
	    sendDone(err);
	  
	}
    }

    command error_t Send.cancel(message_t *msg) {
	if(curTxMsg == msg) {
	    atomic rState = RADIO_ON;
	    return SUCCESS;
	}	
	return FAIL;
    }

    command uint8_t Send.maxPayloadLength() {
	return call SubSend.maxPayloadLength();
    }
    
    command void *Send.getPayload(message_t* msg, uint8_t len) {
	return call SubSend.getPayload(msg,len);
    }
    
    /* 
     * Receive commands
     */
    event message_t *SubReceive.receive(message_t *msg,void *payload, uint8_t len) {
	
	if ((getHeader(msg)->ack & 0xFE ) == lastSeqNo
	    && call AMPacket.destination(msg) == AM_BROADCAST_ADDR) {
	    return msg;
	} else {
	    lastSeqNo = getHeader(msg)->ack & 0xFE;
	    if(!call SendTimeout.isRunning()) {
		// catched a packet between pktSend
		call OffTimer.startOneShot(DELAY_AFTER_RECEIVE);
	    }

	    return signal Receive.receive(msg,payload,len);
	}
    }
    
    uint16_t getActualDutyCycle(uint16_t dutyCycle) {
	if(dutyCycle > 10000) {
	    return 10000;
	} else if(dutyCycle == 0) {
	    return 1;
	}
	return dutyCycle;
    }

    command void LowPowerListening.setLocalSleepInterval(uint16_t sTime) {
 	if(sleepTime == 0 && sTime >0) {
	    call LPLControl.setMode(RX);
	    call OnTimer.startOneShot(DELAY_AFTER_RECEIVE);
	}
	sleepTime = sTime;
    }
    
    command uint16_t LowPowerListening.getLocalSleepInterval() {
	return sleepTime;
    }

    command void LowPowerListening.setLocalDutyCycle(uint16_t d) {
	return call LowPowerListening.setLocalSleepInterval(call LowPowerListening.dutyCycleToSleepInterval(d));
    }

    command uint16_t LowPowerListening.getLocalDutyCycle() {
	return call LowPowerListening.sleepIntervalToDutyCycle(sleepTime);
    }

    command void LowPowerListening.setRxSleepInterval(message_t *msg, uint16_t sleepIntervalMs) {
	xe1205_footer_t *footer = getFooter(msg);

	footer->rxInterval =  sleepIntervalMs;
    }

    command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg) {
	xe1205_footer_t *footer = getFooter(msg);

	if (footer->rxInterval >= 0)
	    return sleepTime;
	else
	    return -(footer->rxInterval + 1);
    }

    command void LowPowerListening.setRxDutyCycle(message_t *msg, uint16_t dCycle) {
	getFooter(msg)->rxInterval =  call LowPowerListening.dutyCycleToSleepInterval(dCycle);
    }

    command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg) {
	return call LowPowerListening.sleepIntervalToDutyCycle(getFooter(msg)->rxInterval);
    }

    command uint16_t LowPowerListening.dutyCycleToSleepInterval(uint16_t dCycle) {
	dCycle = getActualDutyCycle(dCycle);

	if(dCycle == 10000) {
	    return 0;
	}
	return (DELAY_AFTER_RECEIVE * (10000 - dCycle)) / dCycle;
    }

    command uint16_t LowPowerListening.sleepIntervalToDutyCycle(uint16_t sInterval) {
	if(sInterval == 0) {
	    return 10000;
	}
	
	return getActualDutyCycle((DELAY_AFTER_RECEIVE * 10000) 
				  / (sInterval + DELAY_AFTER_RECEIVE));
    }
}
