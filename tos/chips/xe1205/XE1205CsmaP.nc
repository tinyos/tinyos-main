/* Copyright (c) 2007 Shockfish SA
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Maxime Muller
 *
 */

#include "XE1205.h"
#include "XE1205LowPowerListening.h"

#define MAX(X,Y) X>Y ? X:Y

module XE1205CsmaP {

    provides {
	interface Init @atleastonce();
	interface SplitControl @atleastonce();
	interface Send;
	interface Receive;
	interface CsmaControl;
	interface LPLControl;
	interface CsmaBackoff[am_id_t amId];
    }
    uses {
	interface SplitControl as SubControl;
	interface Receive as SubReceive;
	interface Send as SubSend;
	interface XE1205PhyRssi as Rssi;
	interface XE1205PhyConf as RadioConf;
	interface Timer<TMilli> as BackoffTimer;
	interface Random;
    }
}
implementation {

    enum {
	RADIO_DISABLED,
	RADIO_IDLE,
	RADIO_RX,
	RADIO_TX,
    };

    uint8_t rState;
    uint8_t rxRssi;
    uint8_t clrRssi;
    norace uint8_t rssiSampleCnt;
    bool enableCCA;

    message_t * txMsg;
    uint8_t txLen;
    enum {
	RSSI_RX = 0,
	RSSI_CLR = 1,
    };
    uint16_t MA_LENGTH = 8;
    uint8_t MAX_RSSI_SAMPLE = 4;
    norace float RSSI_RX_MA;
    norace float RSSI_CLR_MA;
    
    /*
     * function prototypes
     */

    task void readRssi();
    task void send();
    
    command error_t Init.init() {
	rssiSampleCnt=0;
	rState = RADIO_DISABLED;
	RSSI_RX_MA = RSSI_ABOVE_85;
	RSSI_CLR_MA = RSSI_90_TO_85;
	return SUCCESS;
    }
    
    command error_t SplitControl.start() {
	return call SubControl.start();
    }

    event void SubControl.startDone(error_t err) {
	if (err!=SUCCESS) {
	    atomic {
	    if (rState == RADIO_TX)
		signal Send.sendDone(txMsg,FAIL);
	    else
		signal SplitControl.startDone(FAIL);
	    }
	} else {
	    atomic {
		if (rState == RADIO_TX) {
		    if(enableCCA==TRUE) {
			if(SUCCESS != post readRssi()) {
			    signal Send.sendDone(txMsg,FAIL);
			    return;
			}
		    } 
		    else {
			post send();
			return;
			if (SUCCESS != post send()) {
			    signal Send.sendDone(txMsg,FAIL);
			    return;
			}
		    }
		}
		if(SUCCESS != post readRssi())
		    signal SplitControl.startDone(FAIL);
	    }
	}
    }

    command error_t SplitControl.stop() { 

	return call SubControl.stop();
    }

    event void SubControl.stopDone(error_t err) {
	atomic {
	if (rState == RADIO_RX) // LPL: shutdown if no activity
	    if (err==SUCCESS)
		 rState = RADIO_IDLE;
	}
	signal SplitControl.stopDone(err);
    }



    void updateRssiMA(uint8_t maType, uint8_t value) {

	switch (maType) {
	case RSSI_CLR:
	    if((float)value < MAX(RSSI_RX_MA,RSSI_RX_MA))
		RSSI_CLR_MA = (RSSI_CLR_MA*(MA_LENGTH - 1)+ value )/(MA_LENGTH);
	    break;
	    
	case RSSI_RX:
	    RSSI_RX_MA  = (RSSI_RX_MA*(MA_LENGTH - 1)+ value )/(MA_LENGTH);
	    break;

	default:
	    break;
	}
    }

    event message_t *SubReceive.receive(message_t* msg, void* payload, uint8_t len){
	
	uint8_t strgth = ((xe1205_metadata_t*)((uint8_t*)msg->footer + sizeof(xe1205_footer_t)))->strength;
	updateRssiMA(RSSI_RX, strgth);
	return signal Receive.receive(msg, payload, len);
    }

    command error_t Send.send(message_t* msg, uint8_t len) {
	error_t err;
	atomic {
	    switch (rState) {

	    case RADIO_DISABLED:
		return EOFF;

	    default:
	
		rState = RADIO_TX;
		atomic txMsg = msg;
		atomic txLen = len;
		err = call SubControl.start();
		return err;
	    }
	}
    }
    
    task void send() {
	if (SUCCESS != call SubSend.send(txMsg, txLen)) {
	    atomic rState = RADIO_IDLE;
	    signal Send.sendDone(txMsg, FAIL);	 
	}
    }

    event void SubSend.sendDone(message_t *msg, error_t err) {
	atomic rState = RADIO_IDLE;
	signal Send.sendDone(msg, err);
    }

    command void* Send.getPayload(message_t* m) {
	return m->data;
    }

    command uint8_t Send.maxPayloadLength() {
	return TOSH_DATA_LENGTH;
    }

    command error_t Send.cancel( message_t* p_msg ) {
	return FAIL;
    }

    command uint8_t Receive.payloadLength(message_t* msg) {
	return call SubReceive.payloadLength(msg);
    }

    command void *Receive.getPayload(message_t* msg, uint8_t* len) {
	return call SubReceive.getPayload(msg, len);
    }
    
    task void readRssi() {
	if(SUCCESS!=call Rssi.getRssi()) {
	 
	    atomic {
	    if (rState == RADIO_TX) {    
		signal Send.sendDone(txMsg, FAIL);
	    } else {
		signal SplitControl.startDone(FAIL);
	    }
	    }
	}
    }


    event void BackoffTimer.fired() {
	rssiSampleCnt = 0;
	if(SUCCESS != post send()) {
	    atomic rState = RADIO_IDLE;
	    signal Send.sendDone(txMsg,FAIL);
	}
    }
    async event void Rssi.rssiDone(uint8_t val) {
	
	updateRssiMA(RSSI_CLR, val);
	atomic {
	    if (rState == RADIO_DISABLED) {
		rState = RADIO_IDLE;
		signal SplitControl.startDone(SUCCESS);
		return;
	    }
	}

	// RX for LPL only
	atomic {
	if (rState == RADIO_RX) {
	    if (RSSI_CLR_MA >= (float)val) { // go back to sleep
		call SubControl.stop();
		return;
	    } else
		// tell lpl layer we have some activity
		signal SplitControl.startDone(SUCCESS);
	}
	
	// TX
	if (rState == RADIO_TX) {
	    rssiSampleCnt++;
	    if ( RSSI_RX_MA >= (float)val || RSSI_CLR_MA >= (float)val || !enableCCA) { // it's a go
		if (enableCCA) {
		    call BackoffTimer.startOneShot(signal CsmaBackoff.initial[((xe1205_header_t*)(txMsg->data -  sizeof(xe1205_header_t)))->type](txMsg));
		} else
		    post send();
		return;
	    }
	    else 
		if (enableCCA && rssiSampleCnt < MAX_RSSI_SAMPLE) {
		    post readRssi();
		} else {
		    call BackoffTimer.startOneShot(signal CsmaBackoff.congestion[((xe1205_header_t*)(txMsg->data -  sizeof(xe1205_header_t)))->type](txMsg));
		}
	    }
	}
    }
    
    async command void LPLControl.setMode(uint8_t mode) {
	switch (mode) {

	case RX:
	    atomic {
		if(rState!=RADIO_TX)
		    rState = RADIO_RX;
	    }
	    break;

	case IDLE:
	    atomic rState = RADIO_IDLE;

	default:
	    return;
	}
    }
    
    async command void CsmaControl.enableCca() {
	atomic enableCCA = TRUE;
    }
    
    async command void CsmaControl.disableCca() {
	atomic enableCCA = FALSE;
    }

 default async event uint16_t CsmaBackoff.initial[am_id_t amId](message_t *m) { 
     return (call Random.rand16() & 0x07) + 1;
 }
 
 default async event uint16_t CsmaBackoff.congestion[am_id_t amId](message_t *m) { 
     return (call Random.rand16() & 0xF) + 1;
 }

}
