/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004-2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */



#include "radiopacketfunctions.h"
#include "flagfunctions.h"
#include "PacketAck.h"

 /**
  * An implementation of a Csma Mac.
  * 
  * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
  * @author: Kevin Klues (klues@tkn.tu-berlin.de)
  * @author Philipp Huppertz (huppertz@tkn.tu-berlin.de)
*/

// #define MACM_DEBUG                 // debug...
module CsmaMacP {
    provides {
        interface SplitControl;
        interface MacSend;
        interface MacReceive;
        interface Packet;
    }
    uses {
        interface StdControl as CcaStdControl;
        interface PhySend as PacketSend;
        interface PhyReceive as PacketReceive;
        interface RadioTimeStamping;
        
        interface Tda5250Control as RadioModes;  
        interface ResourceRequested as RadioResourceRequested;

        interface UartPhyControl;
        interface Packet as SubPacket;
        
        interface ChannelMonitor;
        interface ChannelMonitorControl;  
        interface ChannelMonitorData;
        interface Resource as RssiAdcResource;

        interface Random;

        interface Timer<TMilli> as ReRxTimer;
        interface Duplicate;
        interface TimeDiff16;
        
        interface Alarm<T32khz, uint16_t> as Timer;
        async command am_addr_t amAddress();
        interface LocalTime<T32khz> as LocalTime32kHz;
        
#ifdef MACM_DEBUG
        interface SerialDebug;
#endif
    }
}
implementation
{
    /****** debug vars & defs & functions  ***********************/
#ifdef MACM_DEBUG
    void sdDebug(uint16_t p) {
        call SerialDebug.putPlace(p);
    };
#else
    void sdDebug(uint16_t p) {};
#endif

    /******* constants and type definitions *********************/
    enum {

        BYTE_TIME=ENCODED_32KHZ_BYTE_TIME,           // phy encoded
        PREAMBLE_BYTE_TIME=TDA5250_32KHZ_BYTE_TIME,  // no coding
        PHY_HEADER_TIME=6*PREAMBLE_BYTE_TIME,        // 6 Phy Preamble
        TIME_CORRECTION=TDA5250_32KHZ_BYTE_TIME+2,   // difference between txSFD and rxSFD

        
        SUB_HEADER_TIME=PHY_HEADER_TIME + sizeof(tda5250_header_t)*BYTE_TIME,
        SUB_FOOTER_TIME=2*BYTE_TIME, // 2 bytes crc 
        MAXTIMERVALUE=0xFFFF,        // helps to compute backoff
        DATA_DETECT_TIME=17,
        RX_SETUP_TIME=102,    // time to set up receiver
        TX_SETUP_TIME=58,     // time to set up transmitter
        ADDED_DELAY = 30,
        RX_ACK_TIMEOUT=RX_SETUP_TIME + PHY_HEADER_TIME + 2*ADDED_DELAY,
        TX_GAP_TIME=RX_ACK_TIMEOUT + TX_SETUP_TIME + 33,
        MAX_SHORT_RETRY=7,
        MAX_LONG_RETRY=4,
        BACKOFF_MASK=0xFFF,  // minimum time around one packet time
        MIN_PREAMBLE_BYTES=2,
        TOKEN_ACK_FLAG = 64,
        TOKEN_ACK_MASK = 0x3f,
        INVALID_SNR = 0xffff
    };
    
/**************** Module Global Variables  *****************/
    
    /* state vars & defs */
    typedef enum {
        CCA,             // clear channel assessment
        CCA_ACK,
        SW_RX,           // switch to receive
        RX,              // rx mode done, listening & waiting for packet
        SW_RX_ACK,
        RX_ACK,
        RX_ACK_P,
        RX_P,
        SW_TX,
        TX,
        SW_TX_ACK,
        TX_ACK,
        INIT
    } macState_t;

    /* flags */
    typedef enum {
        RSSI_STABLE = 1,
        RESUME_BACKOFF = 2,
        CANCEL_SEND = 4,
        CCA_PENDING = 8
    } flags_t;

    /* Packet vars */
    message_t* txBufPtr = NULL;
    message_t ackMsg;

    uint8_t txLen;
    uint8_t shortRetryCounter = 0;

    uint8_t longRetryCounter = 0;
    unsigned checkCounter;
    
    macState_t macState = INIT;
    uint8_t flags = 0;
    uint8_t seqNo;
    
    uint16_t restLaufzeit;

    uint16_t rssiValue = 0;

    uint32_t rxTime = 0;
    
    /****** Secure switching of radio modes ***/
    
    task void SetRxModeTask();
    task void SetTxModeTask();

    task void ReleaseAdcTask() {
        macState_t ms;
        atomic ms = macState;
        if(isFlagSet(&flags, CCA_PENDING)) {
          post ReleaseAdcTask(); 
        }
        else {
        	if((ms > CCA)  && (ms != INIT) && call RssiAdcResource.isOwner()) {
          	  call RssiAdcResource.release();
        	}	
        }
    }
    
    void setRxMode();
    void setTxMode();

    void requestAdc() {
        if(macState != INIT) {
          call RssiAdcResource.immediateRequest();
        }
        else {
            call RssiAdcResource.request();
        }
    }
    
    void setRxMode() {
        rssiValue = INVALID_SNR;
        if(call RadioModes.RxMode() == FAIL) {
            post SetRxModeTask();
        }
        if(macState == INIT) {
          requestAdc();
        } else {
          post ReleaseAdcTask();
        }
    }
    
    task void SetRxModeTask() {
        atomic {
            if((macState == SW_RX) ||
               (macState == SW_RX_ACK) ||
               (macState == INIT)) setRxMode();
        }
    }

    void setTxMode() {
        clearFlag(&flags, RSSI_STABLE);
        if(call RadioModes.TxMode() == FAIL) {
            post SetTxModeTask();
        }
        post ReleaseAdcTask();
    }
    
    task void SetTxModeTask() {
        atomic {
            if((macState == SW_TX) ||
               (macState == SW_TX_ACK)) setTxMode();
        }
    }

    /**************** Helper functions ********/

    task void postponeReRx() {
        call ReRxTimer.startOneShot(5000);
    }

    uint16_t backoff(uint8_t counter) {
        uint16_t mask = BACKOFF_MASK >> (MAX_LONG_RETRY - counter);
        return (call Random.rand16() & mask);
    }

    void interruptBackoffTimer() {
        if(call Timer.isRunning()) {
            restLaufzeit = call TimeDiff16.computeDelta(call Timer.getAlarm(), call Timer.getNow());
            call Timer.stop();
            if(restLaufzeit > BACKOFF_MASK) {
                restLaufzeit = call Random.rand16() & 0xFF;
            }
            setFlag(&flags, RESUME_BACKOFF);
        }
    }

    void storeStrength(message_t *m) {
        if(rssiValue != INVALID_SNR) {
            (getMetadata(m))->strength = rssiValue;
        }
        else {
            if(call RssiAdcResource.isOwner()) {
                (getMetadata(m))->strength = call ChannelMonitorData.readSnr();
            }
            else {
                (getMetadata(m))->strength = 1;
            }
        }
    }

    void signalSendDone(error_t error) {
        message_t *m;
        error_t e = error;
        atomic {
            m = txBufPtr;
            txBufPtr = 0;
            txLen  = 0;
            longRetryCounter = 0;
            shortRetryCounter = 0;
            if(isFlagSet(&flags, CANCEL_SEND)) {
                e = ECANCEL;
            }
            storeStrength(m);
            clearFlag(&flags, CANCEL_SEND);
        }
        signal MacSend.sendDone(m, e);
    }

    void updateLongRetryCounters() {
        longRetryCounter++;
        shortRetryCounter = 1;
        if(longRetryCounter > MAX_LONG_RETRY) {
            sdDebug(13);
            getMetadata(txBufPtr)->ack = WAS_NOT_ACKED;
            signalSendDone(FAIL);
        }
    }

    void updateRetryCounters() {
        shortRetryCounter++;
        if(shortRetryCounter > MAX_SHORT_RETRY) {
            longRetryCounter++;
            shortRetryCounter = 1;
            if(longRetryCounter > MAX_LONG_RETRY) {
                getMetadata(txBufPtr)->ack = WAS_NOT_ACKED;
                signalSendDone(FAIL);
            }
        }
    }
    
    void computeBackoff() {
        if(!isFlagSet(&flags, RESUME_BACKOFF)) {
            setFlag(&flags, RESUME_BACKOFF);
            restLaufzeit = backoff(longRetryCounter);
            updateRetryCounters();
            sdDebug(92);
        }
    }

    bool isNewMsg(message_t* msg) {
        return call Duplicate.isNew(getHeader(msg)->src, getHeader(msg)->dest,
                                    (getHeader(msg)->token) & TOKEN_ACK_MASK);
    }
    
    void rememberMsg(message_t* msg) {
        call Duplicate.remember(getHeader(msg)->src, getHeader(msg)->dest,
                                (getHeader(msg)->token) & TOKEN_ACK_MASK);
    }
    
    void checkSend() {
        if((txBufPtr != NULL) && (macState == RX) && (!call Timer.isRunning())) {
            macState = CCA;
            checkCounter = 0;
            requestAdc();
            call Timer.start(DATA_DETECT_TIME);
            sdDebug(170);
        }
        else {
            sdDebug(171);
            post ReleaseAdcTask();
        }
    }
    
    bool needsAckRx(message_t* msg) {
        bool rVal = FALSE;
        uint8_t token;
        if(getHeader(msg)->dest < AM_BROADCAST_ADDR) {
            token = getHeader(msg)->token;
            if(isFlagSet(&token, ACK_REQUESTED)) rVal = TRUE;
        }
        return rVal;
    }

    bool needsAckTx(message_t* msg) {
        bool rVal = FALSE;
        if(getHeader(msg)->dest < AM_BROADCAST_ADDR) {
            if((getMetadata(msg)->ack == ACK_REQUESTED) || (getMetadata(msg)->ack != NO_ACK_REQUESTED)) {
                rVal = TRUE;
            }
        }
        return rVal;
    }

    void prepareAck(message_t* msg) {
        uint8_t rToken = getHeader(msg)->token & TOKEN_ACK_MASK;
        setFlag(&rToken, TOKEN_ACK_FLAG);
        getHeader(&ackMsg)->token = rToken;
        getHeader(&ackMsg)->src = call amAddress();
        getHeader(&ackMsg)->dest = getHeader(msg)->src;
        getHeader(&ackMsg)->type = getHeader(msg)->type;
    }

    bool msgIsForMe(message_t* msg) {
        if(getHeader(msg)->dest == AM_BROADCAST_ADDR) return TRUE;
        if(getHeader(msg)->dest == call amAddress()) return TRUE;
        return FALSE;
    }

    bool ackIsForMe(message_t* msg) {
        uint8_t localToken = seqNo;
        setFlag(&localToken, TOKEN_ACK_FLAG);
        if((getHeader(msg)->dest == call amAddress()) && (localToken == getHeader(msg)->token)) return TRUE;
        return FALSE;
    }
    
    bool isControl(message_t* m) {
        uint8_t token = getHeader(m)->token;
        return isFlagSet(&token, TOKEN_ACK_FLAG);
    }
    
    /****************  SplitControl  *****************/

    task void StartDoneTask() {
        atomic {
            macState = RX;
            call UartPhyControl.setNumPreambles(MIN_PREAMBLE_BYTES);
        }
        post ReleaseAdcTask();
        signal SplitControl.startDone(SUCCESS);
    }

    command error_t SplitControl.start() {
        call CcaStdControl.start();
        atomic {
            macState = INIT;
            
            setRxMode();
            sdDebug(1);
        }
        return SUCCESS;
    }

    task void StopDone() {
        atomic {
            if (macState != RX) {
                post StopDone();
                sdDebug(2);
            } else {
                sdDebug(3);
                call Timer.stop();
                txBufPtr = NULL;
                macState = INIT;
                shortRetryCounter = 0;
                longRetryCounter = 0;
                flags = 0;
                signal SplitControl.stopDone(SUCCESS); 
            }
        }
    }
    
    command error_t SplitControl.stop() {
        call CcaStdControl.stop();
        sdDebug(4);
        post StopDone();
        return SUCCESS;
    }
    
    /****** Packet interface ********************/
    command void Packet.clear(message_t* msg) {
        call SubPacket.clear(msg);
    }
    
    command uint8_t Packet.payloadLength(message_t* msg) {
        return call SubPacket.payloadLength(msg);
    }
    
    command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
        call SubPacket.setPayloadLength(msg,len);
    }
    
    command uint8_t Packet.maxPayloadLength() {
        return call SubPacket.maxPayloadLength();
    }
    
    command void* Packet.getPayload(message_t* msg, uint8_t len) {
        return call SubPacket.getPayload(msg, len);
    }
   
    /****** Radio(Mode) events *************************/
    async event void RadioModes.RssiStable() {
        atomic  {
            setFlag(&flags, RSSI_STABLE);
            if(macState == INIT) {
                sdDebug(11);
                if(call RssiAdcResource.isOwner()) {
                    call ChannelMonitorControl.updateNoiseFloor();
                }
            }
            else {
                sdDebug(12);
            }
        }
    }

    async event void RadioModes.RxModeDone() {
        post postponeReRx();
        atomic {
            if(macState == SW_RX) {
                sdDebug(21);
                macState = RX;
                
                if(isFlagSet(&flags, RESUME_BACKOFF)) {
                    clearFlag(&flags, RESUME_BACKOFF);
                    call Timer.start(restLaufzeit);
                } else {
                    call Timer.start(backoff(longRetryCounter));
                }
            }
            else if(macState == SW_RX_ACK) {
                sdDebug(22);
                macState = RX_ACK;
            }
            else if(macState == INIT) {
                sdDebug(24);
            }
            else {
                sdDebug(25);
            }
        }
    }

    async event void RadioModes.TxModeDone() {
        post postponeReRx();
        atomic {
            if(macState == SW_TX) {
                sdDebug(30);
                if(txBufPtr) {
                    macState = TX;
                    if(call PacketSend.send(txBufPtr, txLen) == SUCCESS) {
                        sdDebug(31);
                    } else {
                        sdDebug(32);
                    }
                }
            }
            else if(macState == SW_TX_ACK) {
                macState = TX_ACK;
                
                if(call PacketSend.send(&ackMsg, 0) == SUCCESS) {
                    sdDebug(53);
                } else {
                    sdDebug(54);
                }
            }
            else {
                sdDebug(33);
            }
        }
    }

    /****** MacSend events *************************/    
    async command error_t MacSend.send(message_t* msg, uint8_t len) {
        error_t err = SUCCESS;
        atomic {
            if((shortRetryCounter == 0) && (txBufPtr == NULL) && (macState != INIT)) { 
              sdDebug(40);
                shortRetryCounter = 1;
                longRetryCounter = 1;
                txBufPtr = msg;
                txLen = len;
                sdDebug(10);
                sdDebug(len);
                seqNo++;
                if(seqNo >= TOKEN_ACK_FLAG) seqNo = 1;
                getHeader(msg)->token = seqNo;
                if(needsAckTx(msg)) getHeader(msg)->token |= ACK_REQUESTED;
                if(macState != RX_P) checkSend();
            }
            else {
                sdDebug(41);
                err = EBUSY;
            }
        }
        return err;
    }

    async command error_t MacSend.cancel(message_t* msg) {
        error_t err = SUCCESS;
        if((shortRetryCounter != 0) && (txBufPtr == msg) &&
           (macState != TX) && (macState != RX_ACK) && (macState != SW_RX_ACK)) {
            sdDebug(50);
            shortRetryCounter = 0;
            txBufPtr = NULL;
            txLen = 0;
            signal MacSend.sendDone(msg, ECANCEL);
        }
        else {
            sdDebug(51);
            err = FAIL;
        }
        return err;
    }
    
    /****** PacketSerializer events **********************/
    async event void PacketReceive.receiveDetected() {
        rssiValue = INVALID_SNR;
        if(macState <= RX_ACK) {
            sdDebug(60);
            interruptBackoffTimer();
            if(macState == CCA) computeBackoff();
        }
        if(macState <= RX) {
            sdDebug(61);
            macState = RX_P;
            
            requestAdc();
        }
        else if(macState <= RX_ACK) {
            sdDebug(62);
            macState = RX_ACK_P;
            
        }
        else if(macState == INIT) {
            sdDebug(63);
        }
        else {
          post ReleaseAdcTask();  
          sdDebug(64);
        } 
    }
    
    async event message_t* PacketReceive.receiveDone(message_t* msg, void* payload, uint8_t len, error_t error) {
        message_t* m = msg;
        bool isCnt;
        macState_t action = RX;
        if(macState == RX_P) {
            if(error == SUCCESS) {
                sdDebug(82);
                isCnt = isControl(msg);
                if(msgIsForMe(msg)) {
                    if(!isCnt) {
                        storeStrength(msg);
                        if(isNewMsg(m)) {
                            m = signal MacReceive.receiveDone(msg);
                            rememberMsg(m);   
                        }
                        if(needsAckRx(msg)) {
                            sdDebug(87);
                            action = CCA_ACK;
                        } else {
                            sdDebug(88);
                        }
                    }
                    else {
                        sdDebug(89);
                    }
                }
                else {
                    sdDebug(90);
                }
            }
            else {
                sdDebug(91);
            }
        }
        else if(macState == RX_ACK_P) {
            if(error == SUCCESS) {
                if(ackIsForMe(msg)) {
                    sdDebug(92);
                    (getMetadata(txBufPtr))->ack = WAS_ACKED;
                    signalSendDone(SUCCESS);
                }
                else {
                    sdDebug(93);
                    updateLongRetryCounters();
                }
            }
            else {
                if(call Timer.isRunning()) {
                    sdDebug(94);
                    action = RX_ACK;
                }
                else {
                    sdDebug(95);
                    if(needsAckTx(txBufPtr)) {
                        updateLongRetryCounters();
                    }
                    else {
                        signalSendDone(SUCCESS);
                    }
                }
            }
        }
        else if(macState == INIT) {
            action = INIT;
        }
        if(action == CCA_ACK) {
            prepareAck(msg);
            macState = CCA_ACK;
            
            call Timer.start(RX_SETUP_TIME - TX_SETUP_TIME + ADDED_DELAY);
        }
        else if(action == RX_ACK) {
            macState = RX_ACK;
            
        }
        else if(action == RX) {
            macState = RX;
            
            if(isFlagSet(&flags, RESUME_BACKOFF)) {
                clearFlag(&flags, RESUME_BACKOFF);
                call Timer.start(restLaufzeit);
            }
            else {
                call Timer.start(backoff(longRetryCounter));
            }
        }
        else if(action == TX) {
            macState = SW_TX;
            
            setTxMode();
        }
        else if(action == INIT) {
            
        }
        else {
            sdDebug(94);
        }
        post ReleaseAdcTask();
        return m;        
    }

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
        if(macState == TX) {
            if(needsAckTx(msg)) {
                sdDebug(97);
                macState = SW_RX_ACK;
                
                call Timer.start(RX_ACK_TIMEOUT);
            } else {
                sdDebug(99);
                signalSendDone(error);
                macState = SW_RX;
                
            }
            setRxMode();
        }
        else if(macState == TX_ACK) {
            macState = SW_RX;
            
            setRxMode();
        }
        post ReleaseAdcTask();
    }
       
    
    /****** Timer ******************************/
    void checkOnBusy() {
        if(macState == CCA) {
            computeBackoff();
            macState = RX;
            requestAdc();
            sdDebug(150);
            
            if(!call Timer.isRunning()) call Timer.start(TX_GAP_TIME >> 1);
        } else if(macState == RX) {
            if(!call Timer.isRunning()) call Timer.start(TX_GAP_TIME + backoff(0));
        }
    }

    void checkOnIdle()  {
        if(macState == RX) {
            checkSend();
        }
        else if(macState == CCA) {
            checkCounter++;
            if(checkCounter < 3) {
                sdDebug(158);                
                call Timer.start((TX_GAP_TIME + backoff(0))>>1);
                requestAdc();
            }
            else {
                call Timer.stop();
                sdDebug(159);
                macState = SW_TX;
                
                setTxMode();
            }
        }
    }
    
    async event void Timer.fired() {
        sdDebug(100);
        if(macState == CCA) {
            if((!call RssiAdcResource.isOwner()) || (call ChannelMonitor.start() != SUCCESS)) {
                if(call UartPhyControl.isBusy()) {
                    sdDebug(101);
                    checkOnBusy();
                }
                else {
                    sdDebug(102);
                    checkOnIdle();
                }
            } else {
              setFlag(&flags, CCA_PENDING);
            }
        }
        else if(macState == RX_ACK) {
            if(needsAckTx(txBufPtr)) {
                sdDebug(103);
                updateLongRetryCounters();
                macState = RX;
                call Timer.start(backoff(longRetryCounter));
            }
            else {
                sdDebug(104);
            }
        }
        else if(macState == CCA_ACK) {
            sdDebug(160);
            macState = SW_TX_ACK;
            
            setTxMode();
        }
        else if((macState == RX_ACK_P) || (macState == RX_P)) {
            sdDebug(108);
        }
        else if(macState == INIT) {
            sdDebug(109);
            post StartDoneTask();
        }
        else {
            sdDebug(110);
            checkSend();
        }
    }
    
    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
      clearFlag(&flags, CCA_PENDING);  
      sdDebug(120);
        checkOnBusy();
    }

    async event void ChannelMonitor.channelIdle() {
      clearFlag(&flags, CCA_PENDING);  
      sdDebug(121);
        checkOnIdle();
    }


    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
        if(macState == INIT) {
            sdDebug(122);
            post StartDoneTask();
        } else {
            sdDebug(124);
        }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
        atomic if((macState == RX_P) || (macState == RX_ACK_P)) rssiValue = data;
        post ReleaseAdcTask();  
    }
    
    /***** unused Radio Modes events **************************/
    
    async event void RadioModes.TimerModeDone() {}

    async event void RadioModes.SleepModeDone() {
        atomic setRxMode();
    }
    
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}

    event void ReRxTimer.fired() {
        atomic {
            if((macState == RX) && (call RadioModes.SleepMode() == SUCCESS)) {
                // ok 
            }
            else {
                post postponeReRx();
            }
        }
    }
    
    /***** abused TimeStamping events **************************/
    async event void RadioTimeStamping.receivedSFD( uint16_t time ) {
        if(call RssiAdcResource.isOwner()) call ChannelMonitorData.getSnr();
        if(macState == RX_P) {
            rxTime = call LocalTime32kHz.get();
            call ChannelMonitor.rxSuccess();
        }
    }
    
    async event void RadioTimeStamping.transmittedSFD( uint16_t time, message_t* p_msg ) {
        if((macState == TX) && (p_msg == txBufPtr)) {
            // to do
        }
    }

    /***** Rssi Resource events ******************/
    event void RssiAdcResource.granted() {
        macState_t ms;
        atomic ms = macState;
        if((ms == INIT) && isFlagSet(&flags, RSSI_STABLE)) {
            sdDebug(145);
            call ChannelMonitorControl.updateNoiseFloor();            
        }
        else {
            sdDebug(146);
            call RssiAdcResource.release();
        }
    }
    
    /***** RadioData Resource events **************/
    async event void RadioResourceRequested.requested() {
      atomic {
        /* This gives other devices the chance to get the Resource
           because RxMode implies a new arbitration round.  */
        if (macState == RX) setRxMode();
      }
    }
    
    // we don't care about urgent Resource requestes
    async event void RadioResourceRequested.immediateRequested() {}
}


