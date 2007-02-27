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
        interface Init;
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
        
        interface Alarm<T32khz, uint16_t> as Timer;
        async command am_addr_t amAddress();

#ifdef MACM_DEBUG
        interface GeneralIO as Led0;
        interface GeneralIO as Led1;
        interface GeneralIO as Led2;
        interface GeneralIO as Led3;
#endif
    }
}
implementation
{

    enum {
        /*
        BYTE_TIME=13,                // byte at 38400 kBit/s, 4b6b encoded
        PREAMBLE_BYTE_TIME=9,        // byte at 38400 kBit/s, no coding
        PHY_HEADER_TIME=51,          // 6 Phy Preamble at 38400
        */

        BYTE_TIME=10,                // byte at 49000 kBit/s, 4b6b encoded
        PREAMBLE_BYTE_TIME=7,        // byte at 49000 kBit/s, no coding
        PHY_HEADER_TIME=40,          // 6 Phy Preamble at 49000

        SUB_HEADER_TIME=PHY_HEADER_TIME + sizeof(tda5250_header_t)*BYTE_TIME,
        SUB_FOOTER_TIME=2*BYTE_TIME, // 2 bytes crc 38400 kBit/s with 4b6b encoding
        MAXTIMERVALUE=0xFFFF,        // helps to compute backoff
        DATA_DETECT_TIME=17,
        RX_SETUP_TIME=111,    // time to set up receiver
        TX_SETUP_TIME=69,     // time to set up transmitter
        ADDED_DELAY = 30,
        RX_ACK_TIMEOUT=RX_SETUP_TIME + PHY_HEADER_TIME + 19 + 2*ADDED_DELAY,
        TX_GAP_TIME=RX_ACK_TIMEOUT + TX_SETUP_TIME + 11,
        MAX_SHORT_RETRY=7,
        MAX_LONG_RETRY=4,
        BACKOFF_MASK=0xFFF,  // minimum time around one packet time
        MIN_PREAMBLE_BYTES=2,
        TOKEN_ACK_FLAG = 64,
        TOKEN_ACK_MASK = 0x3f,
        INVALID_SNR = 0xffff,
        MSG_TABLE_ENTRIES=20,
        MAX_AGE=2*MAX_LONG_RETRY*MAX_SHORT_RETRY,
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
    message_t* txBufPtr;
    message_t ackMsg;

    uint8_t txLen;
    uint8_t shortRetryCounter;

    uint8_t longRetryCounter;
    unsigned checkCounter;
    
    macState_t macState;
    uint8_t flags;
    uint8_t seqNo;
    
    uint16_t restLaufzeit;

    /* duplicate suppression */
    typedef struct knownMessage_t {
        am_addr_t src;
        uint8_t token;
        uint8_t age;
    } knownMessage_t;
    
    knownMessage_t knownMsgTable[MSG_TABLE_ENTRIES];

    task void ageMsgsTask() {
        unsigned i;
        atomic {
            for(i = 0; i < MSG_TABLE_ENTRIES; i++) {
                if(knownMsgTable[i].age <= MAX_AGE) ++knownMsgTable[i].age;
            }
        }
    }

    /****** debug vars & defs & functions  ***********************/
#ifdef MACM_DEBUG
#define HISTORY_ENTRIES 100
    typedef struct {
        int index;
        macState_t state;
        int        place;
    } history_t;
    
    history_t history[HISTORY_ENTRIES];
    unsigned histIndex;
    void storeOldState(int p) {
        atomic {
            history[histIndex].index = histIndex;
            history[histIndex].state = macState;
            history[histIndex].place = p;
            histIndex++;
            if(histIndex >= HISTORY_ENTRIES) histIndex = 0;
        }
    }
#else
    void storeOldState(int p) {};
#endif

    void signalFailure(uint8_t place) {
#ifdef MACM_DEBUG
        unsigned long i;
        atomic {
            for(;;) {
                call Led0.set();
                call Led1.clr();
                call Led2.clr();
                call Led3.clr();
                
                for(i = 0; i < 1000000; i++) {
                    ;
                }

                (place & 1) ? call Led0.set() : call Led0.clr();
                (place & 2) ? call Led1.set() : call Led1.clr();
                (place & 4) ? call Led2.set() : call Led2.clr();
                (place & 8) ? call Led3.set() : call Led3.clr();

                for(i = 0; i < 1000000; i++) {
                    ;
                }

                (macState & 1) ? call Led0.set() : call Led0.clr();
                (macState & 2) ? call Led1.set() : call Led1.clr();
                (macState & 4) ? call Led2.set() : call Led2.clr();
                (macState & 8) ? call Led3.set() : call Led3.clr();

                for(i = 0; i < 1000000; i++) {
                    ;
                }
            }
        }
#endif
    }

    void signalMacState() {
#ifdef MACM_DEBUG
/*
         (macState & 1) ? call Led0.set() : call Led0.clr();
         (macState & 2) ? call Led1.set() : call Led1.clr();
         (macState & 4) ? call Led2.set() : call Led2.clr();
         (macState & 8) ? call Led3.set() : call Led3.clr();
*/
#endif
    }
    
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
        uint16_t now;
        if(call Timer.isRunning()) {
            restLaufzeit = call Timer.getAlarm();
            call Timer.stop();
            now = call Timer.getNow();
            if(restLaufzeit >= now) {
                restLaufzeit = restLaufzeit - now;
            }
            else {
                restLaufzeit +=  MAXTIMERVALUE - now;
            }
            if(restLaufzeit > BACKOFF_MASK) {
                restLaufzeit = backoff(0);
            }
            setFlag(&flags, RESUME_BACKOFF);
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
            clearFlag(&flags, CANCEL_SEND);
        }
        signal MacSend.sendDone(m, e);
    }

    void updateLongRetryCounters() {
        longRetryCounter++;
        shortRetryCounter = 1;
        if(longRetryCounter > MAX_LONG_RETRY) {
            storeOldState(13);
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
            storeOldState(92);
        }
    }

    bool isNewMsg(message_t* msg) {
        uint8_t i;
        for(i=0; i < MSG_TABLE_ENTRIES; i++) {
            if((getHeader(msg)->src == knownMsgTable[i].src) &&
               (((getHeader(msg)->token) & TOKEN_ACK_MASK) == knownMsgTable[i].token) &&
               (knownMsgTable[i].age < MAX_AGE)) {
                knownMsgTable[i].age = 0;
                return FALSE;
            }
        }
        return TRUE;
    }

    unsigned findOldest() {
        unsigned i;
        unsigned oldIndex = 0;
        unsigned age = knownMsgTable[oldIndex].age;
        for(i = 1; i < MSG_TABLE_ENTRIES; i++) {
            if(age < knownMsgTable[i].age) {
                oldIndex = i;
                age = knownMsgTable[i].age;
            }
        }
        return oldIndex;
    }
    
    void rememberMsg(message_t* msg) {
        unsigned oldest = findOldest();
        knownMsgTable[oldest].src = getHeader(msg)->src;
        knownMsgTable[oldest].token = (getHeader(msg)->token) & TOKEN_ACK_MASK;
        knownMsgTable[oldest].age = 0;
    }
    
    void checkSend() {
        if((txBufPtr != NULL) && (macState == RX) && (!call Timer.isRunning())) {
            macState = CCA;
            signalMacState();
            checkCounter = 0;
            requestAdc();
            call Timer.start(DATA_DETECT_TIME);
            storeOldState(170);
        }
        else {
            storeOldState(171);
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
    
    /**************** Init ************************/
    
    command error_t Init.init(){
        unsigned i;
        atomic {
            txBufPtr = NULL;
            macState = INIT;
            signalMacState();
            shortRetryCounter = 0;
            longRetryCounter = 0;
            flags = 0;
            for(i = 0; i < MSG_TABLE_ENTRIES; i++) {
                knownMsgTable[i].age = MAX_AGE;
            }
#ifdef MACM_DEBUG
            histIndex = 0;
#endif
        }
        return SUCCESS;
    }

    /****************  SplitControl  *****************/

    task void StartDoneTask() {
        atomic {
            macState = RX;
            signalMacState();
            call UartPhyControl.setNumPreambles(MIN_PREAMBLE_BYTES);
        }
        post ReleaseAdcTask();
        signal SplitControl.startDone(SUCCESS);
    }

    command error_t SplitControl.start() {
        call CcaStdControl.start();
        atomic {
            macState = INIT;
            signalMacState();
            setRxMode();
            storeOldState(1);
        }
        return SUCCESS;
    }

    task void StopDone() {
        atomic {
            if (macState != RX) {
                post StopDone();
                storeOldState(2);
            } else {
                storeOldState(3);
                call Timer.stop();
                call Init.init();
                signal SplitControl.stopDone(SUCCESS); 
            }
        }
    }
    
    command error_t SplitControl.stop() {
        call CcaStdControl.stop();
        storeOldState(4);
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
    
    command void* Packet.getPayload(message_t* msg, uint8_t* len) {
        return call SubPacket.getPayload(msg, len);
    }
   
    /****** Radio(Mode) events *************************/
    async event void RadioModes.RssiStable() {
        atomic  {
            setFlag(&flags, RSSI_STABLE);
            if(macState == INIT) {
                storeOldState(11);
                if(call RssiAdcResource.isOwner()) {
                    call ChannelMonitorControl.updateNoiseFloor();
                }
            }
            else {
                storeOldState(12);
            }
        }
    }

    async event void RadioModes.RxModeDone() {
        post postponeReRx();
        atomic {
            if(macState == SW_RX) {
                storeOldState(21);
                macState = RX;
                signalMacState();
                if(isFlagSet(&flags, RESUME_BACKOFF)) {
                    clearFlag(&flags, RESUME_BACKOFF);
                    call Timer.start(restLaufzeit);
                } else {
                    call Timer.start(backoff(longRetryCounter));
                }
            }
            else if(macState == SW_RX_ACK) {
                storeOldState(22);
                macState = RX_ACK;
                signalMacState();
            }
            else if(macState == INIT) {
                storeOldState(24);
            }
            else {
                storeOldState(25);
                signalFailure(1);
            }
        }
    }

    async event void RadioModes.TxModeDone() {
        post postponeReRx();
        atomic {
            if(macState == SW_TX) {
                storeOldState(30);
                if(txBufPtr) {
                    macState = TX;
                    signalMacState();
                    if(call PacketSend.send(txBufPtr, txLen) == SUCCESS) {
                        storeOldState(31);
                    } else {
                        storeOldState(32);
                        signalFailure(2);
                    }
                }
            }
            else if(macState == SW_TX_ACK) {
                macState = TX_ACK;
                signalMacState();
                if(call PacketSend.send(&ackMsg, 0) == SUCCESS) {
                    storeOldState(53);
                } else {
                    storeOldState(54);
                    signalFailure(6);
                }
            }
            else {
                storeOldState(33);
                signalFailure(3);
            }
        }
    }

    /****** MacSend events *************************/    
    async command error_t MacSend.send(message_t* msg, uint8_t len) {
        error_t err = SUCCESS;
        atomic {
            if((shortRetryCounter == 0) && (txBufPtr == NULL) && (macState != INIT)) { 
              storeOldState(40);
                shortRetryCounter = 1;
                longRetryCounter = 1;
                txBufPtr = msg;
                txLen = len;
                seqNo++;
                if(seqNo >= TOKEN_ACK_FLAG) seqNo = 1;
                getHeader(msg)->token = seqNo;
                if(needsAckTx(msg)) getHeader(msg)->token |= ACK_REQUESTED;
                if(macState != RX_P) checkSend();
            }
            else {
                storeOldState(41);
                err = EBUSY;
            }
        }
        return err;
    }

    async command error_t MacSend.cancel(message_t* msg) {
        error_t err = SUCCESS;
        if((shortRetryCounter != 0) && (txBufPtr == msg) &&
           (macState != TX) && (macState != RX_ACK) && (macState != SW_RX_ACK)) {
            storeOldState(50);
            shortRetryCounter = 0;
            txBufPtr = NULL;
            txLen = 0;
            signal MacSend.sendDone(msg, ECANCEL);
        }
        else {
            storeOldState(51);
            err = FAIL;
        }
        return err;
    }
    
    /****** PacketSerializer events **********************/
    async event void PacketReceive.receiveDetected() {
        if(macState <= RX_ACK) {
            storeOldState(60);
            interruptBackoffTimer();
            if(macState == CCA) computeBackoff();
        }
        if(macState <= RX) {
          post ReleaseAdcTask();  
          storeOldState(61);
            macState = RX_P;
            signalMacState();
        }
        else if(macState <= RX_ACK) {
            post ReleaseAdcTask();
            storeOldState(62);
            macState = RX_ACK_P;
            signalMacState();
        }
        else if(macState == INIT) {
            storeOldState(63);
        }
        else {
          post ReleaseAdcTask();  
          storeOldState(64);
          signalFailure(4);	
        } 
    }
    
    async event message_t* PacketReceive.receiveDone(message_t* msg, void* payload, uint8_t len, error_t error) {
        message_t* m = msg;
        bool isCnt;
        macState_t action = RX;
        if(macState == RX_P) {
            if(error == SUCCESS) {
                post ageMsgsTask();
                storeOldState(82);
                isCnt = isControl(msg);
                if(msgIsForMe(msg)) {
                    if(!isCnt) {
                        (getMetadata(m))->strength = 10;
                        if(isNewMsg(m)) {
                            m = signal MacReceive.receiveDone(msg);
                            rememberMsg(m);   
                        }
                        if(needsAckRx(msg)) {
                            storeOldState(87);
                            action = CCA_ACK;
                        } else {
                            storeOldState(88);
                        }
                    }
                    else {
                        storeOldState(89);
                    }
                }
                else {
                    storeOldState(90);
                }
            }
            else {
                storeOldState(91);
            }
        }
        else if(macState == RX_ACK_P) {
            if(error == SUCCESS) {
                if(ackIsForMe(msg)) {
                    storeOldState(92);
                    (getMetadata(txBufPtr))->strength = 10;
                    (getMetadata(txBufPtr))->ack = WAS_ACKED;
                    signalSendDone(SUCCESS);
                }
                else {
                    storeOldState(93);
                    updateLongRetryCounters();
                }
            }
            else {
                if(call Timer.isRunning()) {
                    storeOldState(94);
                    action = RX_ACK;
                }
                else {
                    storeOldState(95);
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
            signalMacState();
            call Timer.start(RX_SETUP_TIME - TX_SETUP_TIME + ADDED_DELAY);
        }
        else if(action == RX_ACK) {
            macState = RX_ACK;
            signalMacState();
        }
        else if(action == RX) {
            macState = RX;
            signalMacState();
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
            signalMacState();
            setTxMode();
        }
        else if(action == INIT) {
            
        }
        else {
            storeOldState(94);
            signalFailure(11);
        }
        return m;        
    }

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
        if(macState == TX) {
            if(msg != txBufPtr) signalFailure(12);
            if(needsAckTx(msg)) {
                storeOldState(97);
                macState = SW_RX_ACK;
                signalMacState();
                call Timer.start(RX_ACK_TIMEOUT);
            } else {
                storeOldState(99);
                signalSendDone(error);
                macState = SW_RX;
                signalMacState();
            }
            setRxMode();
        }
        else if(macState == TX_ACK) {
            macState = SW_RX;
            signalMacState();
            setRxMode();
        }
        else {
            signalFailure(13);
        }
    }
       
    
    /****** Timer ******************************/
    void checkOnBusy() {
        if(macState == CCA) {
            computeBackoff();
            macState = RX;
            requestAdc();
            storeOldState(150);
            signalMacState();
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
                storeOldState(158);                
                call Timer.start((TX_GAP_TIME + backoff(0))>>1);
                requestAdc();
            }
            else {
                call Timer.stop();
                storeOldState(159);
                macState = SW_TX;
                signalMacState();
                setTxMode();
            }
        }
    }
    
    async event void Timer.fired() {
        storeOldState(100);
        if(macState == CCA) {
            if((!call RssiAdcResource.isOwner()) || (call ChannelMonitor.start() != SUCCESS)) {
                if(call UartPhyControl.isBusy()) {
                    storeOldState(101);
                    checkOnBusy();
                }
                else {
                    storeOldState(102);
                    checkOnIdle();
                }
            } else {
              setFlag(&flags, CCA_PENDING);
            }
        }
        else if(macState == RX_ACK) {
            if(needsAckTx(txBufPtr)) {
                storeOldState(103);
                updateLongRetryCounters();
                macState = RX;
                call Timer.start(backoff(longRetryCounter));
            }
            else {
                storeOldState(104);
                signalFailure(7);                
            }
        }
        else if(macState == CCA_ACK) {
            storeOldState(160);
            macState = SW_TX_ACK;
            signalMacState();
            setTxMode();
        }
        else if((macState == RX_ACK_P) || (macState == RX_P)) {
            storeOldState(108);
        }
        else if(macState == INIT) {
            storeOldState(109);
            post StartDoneTask();
        }
        else {
            storeOldState(110);
            checkSend();
        }
    }
    
    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
      clearFlag(&flags, CCA_PENDING);  
      storeOldState(120);
        checkOnBusy();
    }

    async event void ChannelMonitor.channelIdle() {
      clearFlag(&flags, CCA_PENDING);  
      storeOldState(121);
        checkOnIdle();
    }


    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
        if(macState == INIT) {
            storeOldState(122);
            post StartDoneTask();
        } else {
            storeOldState(124);
            signalFailure(11);
        }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
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
        if(macState == RX_P) call ChannelMonitor.rxSuccess();
    }
    
    async event void RadioTimeStamping.transmittedSFD( uint16_t time, message_t* p_msg ) {}

    /***** Rssi Resource events ******************/
    event void RssiAdcResource.granted() {
        macState_t ms;
        atomic ms = macState;
        if((ms == INIT) && isFlagSet(&flags, RSSI_STABLE)) {
            storeOldState(145);
            call ChannelMonitorControl.updateNoiseFloor();            
        }
        else {
            storeOldState(146);
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


