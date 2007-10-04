/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * - Description ---------------------------------------------------------
 * low power nonpersistent CSMA MAC, rendez-vous via redundantly sent packets
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */


#include "radiopacketfunctions.h"
#include "flagfunctions.h"
#include "PacketAck.h"
#include "RedMac.h"

module SpeckMacDP {
    provides {
        interface Init;
        interface SplitControl;
        interface MacSend;
        interface MacReceive;
        interface Packet;
        interface Sleeptime;
        interface ChannelCongestion;
    }
    uses {
        interface StdControl as CcaStdControl;
        interface PhySend as PacketSend;
        interface PhyReceive as PacketReceive;
        interface RadioTimeStamping;

        interface Tda5250Control as RadioModes;  

        interface UartPhyControl;
      
        interface ChannelMonitor;
        interface ChannelMonitorControl;  
        interface ChannelMonitorData;
        interface Resource as RssiAdcResource;

        interface Random;

        interface Packet as SubPacket;
        
        interface Alarm<T32khz, uint16_t> as Timer;
        interface Alarm<T32khz, uint16_t> as SampleTimer;
        interface LocalTime<T32khz> as LocalTime32kHz;

        interface Duplicate;
        interface TimeDiff16;
        interface TimeDiff32;

        async command am_addr_t amAddress();
/*
        interface GeneralIO as Led0;
        interface GeneralIO as Led1;
        interface GeneralIO as Led2;
        interface GeneralIO as Led3;        
*/  
#ifdef SPECKMAC_DEBUG
        interface SerialDebug;
#endif
#ifdef SPECKMAC_PERFORMANCE
        interface Performance;
#endif

    }
}
implementation
{
    /****** MAC State machine *********************************/
    typedef enum {
        RX,
        RX_ACK,
        CCA,
        CCA_ACK,
        RX_P,
        RX_ACK_P,
        SLEEP,
        TX,
        TX_ACK,
        INIT,
        STOP
    } macState_t;
    
    macState_t macState;

    /****** debug vars & defs & functions  ***********************/
#ifdef SPECKMAC_DEBUG
    void sdDebug(uint16_t p) {
        call SerialDebug.putPlace(p);
    }
    uint8_t repCounter;
#else
    void sdDebug(uint16_t p) {};
#endif
    
#ifdef SPECKMAC_PERFORMANCE
    macTxStat_t txStat;
    macRxStat_t rxStat;
#endif

    /**************** Module Global Constants  *****************/
    enum {

        BYTE_TIME=21,                 // byte at 23405 kBit/s, 4b6b encoded
        PREAMBLE_BYTE_TIME=14,        // byte at 23405 kBit/s, no coding
        PHY_HEADER_TIME=84,           // 6 Phy Preamble at 23405 bits/s
        TIME_CORRECTION=16,           // difference between txSFD and rxSFD: 475us
                
        SUB_HEADER_TIME=PHY_HEADER_TIME + sizeof(message_header_t)*BYTE_TIME,
        SUB_FOOTER_TIME=2*BYTE_TIME, // 2 bytes crc 
        // DEFAULT_SLEEP_TIME=1625,
        // DEFAULT_SLEEP_TIME=3250,
        // DEFAULT_SLEEP_TIME=6500,
        // DEFAULT_SLEEP_TIME=8192,
        // DEFAULT_SLEEP_TIME=16384,
        DEFAULT_SLEEP_TIME=32768U,
        // DEFAULT_SLEEP_TIME=65535U,
        DATA_DETECT_TIME=17,
        RX_SETUP_TIME=102,    // time to set up receiver
        TX_SETUP_TIME=58,     // time to set up transmitter
        ADDED_DELAY = 30,
        RX_ACK_TIMEOUT = RX_SETUP_TIME + PHY_HEADER_TIME + ADDED_DELAY + 30,
        TX_GAP_TIME = RX_ACK_TIMEOUT + TX_SETUP_TIME + 33,
        // the duration of a send ACK
        ACK_DURATION = SUB_HEADER_TIME + SUB_FOOTER_TIME,
        MAX_SHORT_RETRY=9,
        MAX_LONG_RETRY=3,
        TOKEN_ACK_FLAG = 64,
        TOKEN_ACK_MASK = 0x3f,
        INVALID_SNR = 0xffff,
        // PREAMBLE_LONG = 5,
        // PREAMBLE_SHORT = 2,
        // reduced minimal backoff
        ZERO_BACKOFF_MASK = 0xff
    };
    
    /**************** Module Global Variables  *****************/    
    /* flags */
    typedef enum {
        SWITCHING = 1,
        RSSI_STABLE = 2,
        UNHANDLED_PACKET = 4,
        MESSAGE_PREPARED = 8,
        RESUME_BACKOFF = 16,
        CANCEL_SEND = 32,
        ACTION_DETECTED = 64,
    } flags_t;

    uint8_t flags = 0;
    uint8_t checkCounter = 0;
    uint8_t shortRetryCounter = 0;
    uint8_t longRetryCounter = 0;
    uint16_t networkSleeptime = DEFAULT_SLEEP_TIME;
    uint16_t localSleeptime = DEFAULT_SLEEP_TIME;
    uint16_t rssiValue = 0;
    uint32_t restLaufzeit = 0;
    
    uint32_t rxTime = 0;

    uint8_t congestionLevel = 0;
    
    message_t *txBufPtr = NULL;
    uint16_t txLen = 0;
    red_mac_header_t *txMacHdr = NULL;
    uint16_t seqNo;
    message_t ackMsg;

    uint16_t MIN_BACKOFF_MASK;
    
    /****** Secure switching of radio modes ***/
    void interruptBackoffTimer();
    
    task void SetRxModeTask();
    task void SetTxModeTask();
    task void SetSleepModeTask();

    task void ReleaseAdcTask() {
        bool release = FALSE;
        atomic {
            if((macState >= SLEEP) &&  call RssiAdcResource.isOwner())  {
                release = TRUE;
            }
        }
        if(release) call RssiAdcResource.release(); 
    }

    void requestAdc() {
        if(!call RssiAdcResource.isOwner()) {
            call RssiAdcResource.immediateRequest();
        }
    }

    void setRxMode() {
        setFlag(&flags, SWITCHING);
        clearFlag(&flags, RSSI_STABLE);
        // sdDebug(10);
        checkCounter = 0;
        rssiValue = INVALID_SNR;
        if(call RadioModes.RxMode() == FAIL) {
            post SetRxModeTask();
        }
        else {
#ifdef SPECKMAC_PERFORMANCE
            call Performance.macRxMode();
#endif
        }
        requestAdc();
    }
    
    task void SetRxModeTask() {
        atomic {
            if(isFlagSet(&flags, SWITCHING) && ((macState <= CCA) || (macState == INIT))) setRxMode();
        }
    }

    void setSleepMode() {
        // sdDebug(20);
        clearFlag(&flags, RSSI_STABLE);
        post ReleaseAdcTask();
        setFlag(&flags, SWITCHING);
        if(call RadioModes.SleepMode() == FAIL) {
            post SetSleepModeTask();
        }
        else {
#ifdef SPECKMAC_PERFORMANCE
            call Performance.macSleepMode();
#endif
        }
    }
    
    task void SetSleepModeTask() {
        atomic if(isFlagSet(&flags, SWITCHING) && ((macState == SLEEP) || (macState == STOP))) setSleepMode();
    }


    void setTxMode() {
        post ReleaseAdcTask();
        // sdDebug(30);
        clearFlag(&flags, RSSI_STABLE);
        setFlag(&flags, SWITCHING);
        if(call RadioModes.TxMode() == FAIL) {
            post SetTxModeTask();
        }
        else {
#ifdef SPECKMAC_PERFORMANCE
            call Performance.macTxMode();
#endif
        }
    }

    task void SetTxModeTask() {
        atomic {
            if(isFlagSet(&flags, SWITCHING) && ((macState == TX) || (macState == TX_ACK))) setTxMode();
        }
    }

    /**************** Helper functions ************************/
    void computeBackoff();
    
    void checkSend() {
        if((shortRetryCounter) && (txBufPtr != NULL) && (isFlagSet(&flags, MESSAGE_PREPARED)) && 
           (macState == SLEEP) && (!isFlagSet(&flags, RESUME_BACKOFF)) && (!call Timer.isRunning())) {
            // sdDebug(40);
            macState = CCA;
            checkCounter = 0;
            setRxMode();
        }
/*        else {
            if(txBufPtr) // sdDebug(41);
            if(shortRetryCounter) // sdDebug(42);
            if(isFlagSet(&flags, MESSAGE_PREPARED)) // sdDebug(43);
            if(txBufPtr) {
                if(macState == SLEEP) // sdDebug(44);
                if(!isFlagSet(&flags, RESUME_BACKOFF)) // sdDebug(45);
                if(!call Timer.isRunning()) // sdDebug(46);
            }
        }
*/
    }

    uint32_t backoff(uint8_t counter) {
        uint32_t rVal = call Random.rand16() &  MIN_BACKOFF_MASK;
        return (rVal << counter) + ZERO_BACKOFF_MASK;
    }
    
    bool needsAckTx(message_t* msg) {
        bool rVal = FALSE;
        if(getHeader(msg)->dest < AM_BROADCAST_ADDR) {
            if(getMetadata(msg)->ack != NO_ACK_REQUESTED) {
                rVal = TRUE;
            }
        }
        return rVal;
    }
    
    bool needsAckRx(message_t* msg) {
        bool rVal = FALSE;
        am_addr_t dest = getHeader(msg)->dest;
        uint8_t token;
        if(dest < AM_BROADCAST_ADDR) {
            token = getHeader(msg)->token;
            if(isFlagSet(&token, ACK_REQUESTED)) {
                rVal = TRUE;
            }
        }
        return rVal;
    }

    task void PrepareMsgTask() {
        message_t *msg;
        uint8_t length;
        red_mac_header_t *macHdr;
        uint16_t sT;
        atomic {
            msg = txBufPtr;
            length = txLen;
            sT = networkSleeptime;
        }
        if(msg == NULL) return;
        macHdr = (red_mac_header_t *)call SubPacket.getPayload(msg, sizeof(red_mac_header_t) + length);
        macHdr->repetitionCounter = sT/(length * BYTE_TIME + SUB_HEADER_TIME + SUB_FOOTER_TIME) + 1;
        atomic {
            getHeader(msg)->token = seqNo;
            if(needsAckTx(msg)) getHeader(msg)->token |= ACK_REQUESTED;
            txMacHdr = macHdr;
            setFlag(&flags, MESSAGE_PREPARED);
            if(macState == SLEEP) {
                sdDebug(400);
            } else {
                sdDebug(401);
            }
            if(!call Timer.isRunning()) {
                sdDebug(402);
            } else {
                sdDebug(403);
            }
            if(!isFlagSet(&flags, RESUME_BACKOFF)) {
                sdDebug(404);
            } else {
                sdDebug(405);
            }
            if((macState == SLEEP) && (!call Timer.isRunning()) && (!isFlagSet(&flags, RESUME_BACKOFF))) {
                if((longRetryCounter == 1) &&
                   (getHeader(msg)->dest != AM_BROADCAST_ADDR)) {
                    call Timer.start((call Random.rand16() >> 3) & ZERO_BACKOFF_MASK);
                    sdDebug(406);
                }
                else {
                    call Timer.start(backoff(longRetryCounter));
                    sdDebug(407);
                }
            }
#ifdef SPECKMAC_PERFORMANCE
            txStat.type = getHeader(msg)->type;
            txStat.to = getHeader(msg)->dest;
            txStat.token = getHeader(msg)->token;
            txStat.maxRepCounter = macHdr->repetitionCounter;
            txStat.creationTime =  getMetadata(msg)->time;
#endif
            getMetadata(msg)->maxRepetitions = macHdr->repetitionCounter;
        }
    }

    void storeStrength(message_t *m) {
        if(rssiValue != INVALID_SNR) {
            (getMetadata(txBufPtr))->strength = rssiValue;
        }
        else {
            if(call RssiAdcResource.isOwner()) {
                (getMetadata(txBufPtr))->strength = call ChannelMonitorData.readSnr();
            }
            else {
                (getMetadata(txBufPtr))->strength = 1;
            }
        }
    }


    bool prepareRepetition() {
        bool repeat;
        atomic {
            if(isFlagSet(&flags, CANCEL_SEND)) {
                repeat = txMacHdr->repetitionCounter = 0;
            }
            else {
                repeat = txMacHdr->repetitionCounter;
                txMacHdr->repetitionCounter--;
            }
        }
        return repeat;
    }

    void signalSendDone(error_t error) {
        message_t *m;
        error_t e = error;
        // sdDebug(50);
        atomic {
            m = txBufPtr;
            txBufPtr = NULL;
            txLen  = 0;
#ifdef SPECKMAC_PERFORMANCE
            txStat.repCounter = txMacHdr->repetitionCounter;
            txStat.longRetry = longRetryCounter;
            txStat.shortRetry = shortRetryCounter;
#endif
            longRetryCounter = 0;
            shortRetryCounter = 0;
            storeStrength(m);
            if(isFlagSet(&flags, CANCEL_SEND)) {
                e = ECANCEL;
            }
            clearFlag(&flags, MESSAGE_PREPARED);
            clearFlag(&flags, CANCEL_SEND);
        }
        // sdDebug(3000 + e);
        // sdDebug(4000 + getHeader(m)->type);
        signal MacSend.sendDone(m, e);
#ifdef SPECKMAC_PERFORMANCE
        txStat.success = e;
        txStat.strength = getMetadata(m)->strength;
        call Performance.macTxMsgStats(&txStat);
#endif
    }
    
    void updateRetryCounters() {
        shortRetryCounter++;
        if(shortRetryCounter > MAX_SHORT_RETRY) {
            longRetryCounter++;
            shortRetryCounter = 1;
            if(longRetryCounter > MAX_LONG_RETRY) {
                // sdDebug(60);
                signalSendDone(FAIL);
            }
        }
    }

    void updateLongRetryCounters() {
        atomic {
            clearFlag(&flags, MESSAGE_PREPARED);
            longRetryCounter++;
            shortRetryCounter = 1;
            if(longRetryCounter > MAX_LONG_RETRY) {
                // sdDebug(70);
                signalSendDone(FAIL);
            } else {
                post PrepareMsgTask();
            }
        }
    }

    bool ackIsForMe(message_t* msg) {
        uint8_t localToken = seqNo;
        setFlag(&localToken, TOKEN_ACK_FLAG);
        if((getHeader(msg)->dest == call amAddress()) && (localToken == getHeader(msg)->token)) return TRUE;
        return FALSE;
    }

    void interruptBackoffTimer() {
        if(call Timer.isRunning()) {
            restLaufzeit = call TimeDiff16.computeDelta(call Timer.getAlarm(), call Timer.getNow());
            call Timer.stop();
            sdDebug(10);
            sdDebug(restLaufzeit);
            if(restLaufzeit > MIN_BACKOFF_MASK << MAX_LONG_RETRY) {
                restLaufzeit = call Random.rand16() & ZERO_BACKOFF_MASK;
            }
            sdDebug(11);
            sdDebug(restLaufzeit);
            setFlag(&flags, RESUME_BACKOFF);
        }
    }

    void computeBackoff() {
        if(!isFlagSet(&flags, RESUME_BACKOFF)) {
            setFlag(&flags, RESUME_BACKOFF);
            restLaufzeit = backoff(longRetryCounter);
            sdDebug(20);
            sdDebug(restLaufzeit);
            updateRetryCounters();
        }
    }

    bool msgIsForMe(message_t* msg) {
        if(getHeader(msg)->dest == AM_BROADCAST_ADDR) return TRUE;
        if(getHeader(msg)->dest == call amAddress()) return TRUE;
        if(getHeader(msg)->dest >= RELIABLE_MCAST_MIN_ADDR) return TRUE;
        return FALSE;
    }

    bool isControl(message_t* m) {
        uint8_t token = getHeader(m)->token;
        return isFlagSet(&token, TOKEN_ACK_FLAG);
    }
    
    bool isNewMsg(message_t* msg) {
        return call Duplicate.isNew(getHeader(msg)->src, (getHeader(msg)->token) & TOKEN_ACK_MASK);
    }
    
    void rememberMsg(message_t* msg) {
        call Duplicate.remember(getHeader(msg)->src, (getHeader(msg)->token) & TOKEN_ACK_MASK);
    }

    void prepareAck(message_t* msg) {
        uint8_t rToken = getHeader(msg)->token & TOKEN_ACK_MASK;
        setFlag(&rToken, TOKEN_ACK_FLAG);
        getHeader(&ackMsg)->token = rToken;
        getHeader(&ackMsg)->src = call amAddress();
        getHeader(&ackMsg)->dest = getHeader(msg)->src;
        getHeader(&ackMsg)->type = getHeader(msg)->type;
#ifdef SPECKMAC_DEBUG
        repCounter = ((red_mac_header_t *)
                      call SubPacket.getPayload(msg, sizeof(red_mac_header_t)))->repetitionCounter;
#endif
    }
    
    uint32_t calcGeneratedTime(red_mac_header_t *m) {
        return rxTime - m->time - TIME_CORRECTION;
    }
    
    /**************** Init ************************/
    
    command error_t Init.init(){
        atomic {
            macState = INIT;
            seqNo = call Random.rand16() % TOKEN_ACK_FLAG;
            for(MIN_BACKOFF_MASK = 1; MIN_BACKOFF_MASK < networkSleeptime; ) {
                MIN_BACKOFF_MASK = (MIN_BACKOFF_MASK << 1) + 1;
            }
            MIN_BACKOFF_MASK >>= 2;
        }
#ifdef SPECKMAC_DEBUG
        call SerialDebug.putShortDesc("SpeckMacP");
#endif
        return SUCCESS;
    }

    /****************  SplitControl  *****************/

    task void StartDoneTask() {
        // sdDebug(90);
        atomic  {
            call SampleTimer.start(localSleeptime);
            macState = SLEEP;
        }
        signal SplitControl.startDone(SUCCESS);        
    }
    
    command error_t SplitControl.start() {
        call CcaStdControl.start();
        atomic {
            macState = INIT;
            setRxMode();
            // sdDebug(100);
        }
        return SUCCESS;
    }
    
    task void StopDoneTask() {
        call Init.init();
        // sdDebug(110);
        signal SplitControl.stopDone(SUCCESS);        
    }
    
    command error_t SplitControl.stop() {
        call CcaStdControl.stop();
        call Timer.stop();
        call SampleTimer.stop();
        atomic {
            if((macState == SLEEP) && isFlagSet(&flags, SWITCHING)) {
                macState = STOP;
                // sdDebug(120);
            }
            else {
                macState = STOP;
                setSleepMode();
                // sdDebug(121);
            }
        }
        return SUCCESS;
    }

    /****** Packet interface ********************/
    command void Packet.clear(message_t* msg) {
        call SubPacket.clear(msg);
    }
    
    command uint8_t Packet.payloadLength(message_t* msg) {
        return call SubPacket.payloadLength(msg) - sizeof(red_mac_header_t);
    }
    
    command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
        call SubPacket.setPayloadLength(msg,len + sizeof(red_mac_header_t));
    }
    
    command uint8_t Packet.maxPayloadLength() {
        return call SubPacket.maxPayloadLength() - sizeof(red_mac_header_t);
    }
    
    command void* Packet.getPayload(message_t* msg, uint8_t len) {
        nx_uint8_t *payload = (nx_uint8_t *)call SubPacket.getPayload(msg, len + sizeof(red_mac_header_t));
        return (void*)(payload + sizeof(red_mac_header_t));
    }
    
    /****** Radio(Mode) events *************************/
    async event void RadioModes.RssiStable() {
        setFlag(&flags, RSSI_STABLE);
        if((macState == RX) || (macState == CCA)) {
            call Timer.start(DATA_DETECT_TIME);
            // sdDebug(130);
        }
        else if(macState == RX_P) {
            // sdDebug(131);
            if(call RssiAdcResource.isOwner()) call ChannelMonitorData.getSnr();
        }
        else if(macState == RX_ACK) {
            // if(call RssiAdcResource.isOwner()) call ChannelMonitor.start();
            // sdDebug(132);
        }
        else if(macState == RX_ACK_P) {
        }
        else if(macState == INIT) {
            // sdDebug(133);
            if(call RssiAdcResource.isOwner()) {
                call ChannelMonitorControl.updateNoiseFloor();
            } else {
                call RssiAdcResource.request();
            }
        }
        else if(macState == STOP) {
            // sdDebug(134);
        }
        else {
            // sdDebug(135);
        }
    }
    
    async event void RadioModes.RxModeDone() {
        atomic {
            clearFlag(&flags, SWITCHING);
            if((macState == RX) || (macState == RX_ACK) || (macState == CCA) ||
               (macState == INIT) || (macState == STOP)) {
                // sdDebug(140);
                if(macState != RX_ACK) requestAdc();
            }
            else {
                // sdDebug(141);
            }
        }
    }
    
    async event void RadioModes.TxModeDone() {
        // sdDebug(150);
        atomic {
            clearFlag(&flags, SWITCHING);
            if(macState == TX) {
                setFlag(&flags, ACTION_DETECTED);
                if(call PacketSend.send(txBufPtr, txLen) == SUCCESS) {
                    // sdDebug(151);
                }
                else {
                    // sdDebug(152);
                }
            }
            else if(macState == TX_ACK) {
                if(call PacketSend.send(&ackMsg, 0) == SUCCESS) {
                    // sdDebug(153);
                } else {
                    // sdDebug(154);
                }
            }
            else {
                // sdDebug(155);
            }
        }
    }

    async event void RadioModes.SleepModeDone() {
        // sdDebug(160);
        atomic {
            clearFlag(&flags, SWITCHING);
            if(isFlagSet(&flags, ACTION_DETECTED)) {
                if(congestionLevel < 5) congestionLevel++;
            } else {
                if(congestionLevel > 0) congestionLevel--;
            }
            // if(congestionLevel > 3) // sdDebug(2000 + congestionLevel);
            if(macState == SLEEP) {
                // sdDebug(161);
                if(!call Timer.isRunning()) {
                    // sdDebug(162);
                    if(isFlagSet(&flags, RESUME_BACKOFF)) {
                        // sdDebug(164);
                        clearFlag(&flags, RESUME_BACKOFF);
                        call Timer.start(restLaufzeit);
                        restLaufzeit = 0;
                        sdDebug(30);
                    }
                    else {
                        // sdDebug(165);
                        checkSend();
                    }
                }
            }
            else if(macState == STOP) {
                // sdDebug(168);
                post StopDoneTask();
            }
            signal ChannelCongestion.congestionEvent(congestionLevel);
        }
    }
    
    /****** MacSend events *************************/    
    async command error_t MacSend.send(message_t* msg, uint8_t len) {
        error_t err = SUCCESS;
        atomic {
            if((shortRetryCounter == 0) && (txBufPtr == NULL)) {
                clearFlag(&flags, MESSAGE_PREPARED);
                // sdDebug(5000 + getHeader(msg)->type);
                shortRetryCounter = 1;
                longRetryCounter = 1;
                txBufPtr = msg;
                txLen = len + sizeof(red_mac_header_t);
                seqNo++;
                if(seqNo >= TOKEN_ACK_FLAG) seqNo = 1;
#ifdef SPECKMAC_PERFORMANCE
                txStat.payloadLength = txLen;
                txStat.interfaceTime = call LocalTime32kHz.get();
#endif
            }
            else {
                // sdDebug(171);
                err = EBUSY;
            }
        }
        if(err == SUCCESS) {
            sdDebug(300);
            post PrepareMsgTask();
        }
        return err;
    }

    async command error_t MacSend.cancel(message_t* msg) {
        error_t err = FAIL;
        atomic {
            if(msg == txBufPtr) {
                // sdDebug(320);
                setFlag(&flags, CANCEL_SEND);
                shortRetryCounter = MAX_SHORT_RETRY + 2;
                longRetryCounter  = MAX_LONG_RETRY + 2;
                if(macState == SLEEP) {
                    // sdDebug(321);
                    signalSendDone(ECANCEL);
                }
                else {
                    // sdDebug(322);
                }
                // sdDebug(1000 + macState);
                err = SUCCESS;
            }
            else {
                // sdDebug(323);
                // sdDebug(1100 + macState);
            }
        }
        return err;
    }
    
    /****** PacketSerializer events **********************/
    
    async event void PacketReceive.receiveDetected() {
        rssiValue = INVALID_SNR;
        setFlag(&flags, ACTION_DETECTED);
        call ChannelMonitor.rxSuccess();
        if(macState <= CCA_ACK) {
            if(macState == CCA) {
                sdDebug(100);
                computeBackoff();
#ifdef SPECKMAC_PERFORMANCE
                call Performance.macDetectedOnCca();
#endif
            }
            if(macState != RX_ACK) {
                macState = RX_P;
            } else {
                sdDebug(500);
                macState = RX_ACK_P;
            }
        }
        else if(macState == INIT) {
            // sdDebug(180);
            setFlag(&flags, UNHANDLED_PACKET);
        }
    }
    
    async event message_t* PacketReceive.receiveDone(message_t* msg, void* payload, uint8_t len, error_t error) {
        message_t *m = msg;
        macState_t action = STOP;
        uint32_t nav = 0;
        bool isCnt;
#ifdef SPECKMAC_PERFORMANCE
        rxStat.duplicate = PERF_UNKNOWN;
        rxStat.repCounter = 0xff;
#endif
        // sdDebug(190);
        if(macState == RX_P) {
            // sdDebug(191);
            if(error == SUCCESS) {
                // sdDebug(192);
                isCnt = isControl(msg);
                if(msgIsForMe(msg)) {
                    if(!isCnt) {
                        // sdDebug(193);
                        if(isNewMsg(msg)) {
#ifdef SPECKMAC_PERFORMANCE
                            rxStat.duplicate = PERF_NEW_MSG;
#endif
                            storeStrength(msg);
                            getMetadata(msg)->time = calcGeneratedTime((red_mac_header_t*) payload);
                            getMetadata(msg)->ack = WAS_NOT_ACKED;
                            m = signal MacReceive.receiveDone(msg);
                            // assume a buffer swap -- if buffer is not swapped, assume that the
                            // message was not successfully delivered to upper layers
                            if(m != msg) {
                                // sdDebug(195);
                                rememberMsg(msg);
                            } else {
                                // sdDebug(196);
                                action = RX;
#ifdef SPECKMAC_PERFORMANCE
                                call Performance.macQueueFull();
#endif
                            }
                        }
#ifdef SPECKMAC_PERFORMANCE
                        else {
                            rxStat.duplicate = PERF_REPEATED_MSG;
                        }
#endif                  
                        if(needsAckRx(msg) && (action != RX)) {
                            // sdDebug(197);
                            if(((red_mac_header_t*)payload)->repetitionCounter == 0) {
                                action = CCA_ACK;
                            }
                            else {
                                action = RX;
                            }
                        }
                        else {
                            // sdDebug(198);
                            if(action != RX) {
                                nav = ((red_mac_header_t*)payload)->repetitionCounter *
                                    (SUB_HEADER_TIME + getHeader(msg)->length*BYTE_TIME +
                                     SUB_FOOTER_TIME) + RX_ACK_TIMEOUT + TX_SETUP_TIME + ACK_DURATION;
                                action = SLEEP;
                            }
                        }
                    }
                    else {
                        // sdDebug(199);
                        action = RX;
                    }
                }
                else {
                    // sdDebug(200);
                    action = SLEEP;
                    if(!isCnt) {
                        nav = ((red_mac_header_t*)payload)->repetitionCounter *
                            (SUB_HEADER_TIME + getHeader(msg)->length*BYTE_TIME +
                             SUB_FOOTER_TIME) + RX_ACK_TIMEOUT + TX_SETUP_TIME + ACK_DURATION;
                    }
                }
            }
            else {
                // sdDebug(201);
                action = SLEEP;
            }
        }
        else if(macState == RX_ACK_P) {
            if(error == SUCCESS) {
                if(ackIsForMe(msg)) {
                    sdDebug(510);
                    storeStrength(msg);
                    getMetadata(txBufPtr)->ack = WAS_ACKED;
                    getMetadata(txBufPtr)->repetitions = txMacHdr->repetitionCounter;
                    // sdDebug(203);
                    signalSendDone(SUCCESS);
                    // sdDebug(30000 + getHeader(msg)->src);
                    action = SLEEP;
                }
                else {
                    sdDebug(511);
                    updateLongRetryCounters(); // this will eventually schedule the right backoff
                    macState = SLEEP;          // so much traffic is going on -- take a nap
                    setSleepMode();
                    action = INIT;             // a difficult way to say: do nothing
                }
            }
            else {
                if(call Timer.isRunning()) {
                    sdDebug(512);
                    action = RX_ACK;
                }
                else {
                    sdDebug(513);
                    updateLongRetryCounters();
                    action = RX;
                }
            }
        }
        else {
            // sdDebug(206);
            action = INIT;
        }
        if(action == CCA_ACK) {
            macState = TX_ACK;
            call Timer.start(RX_SETUP_TIME - TX_SETUP_TIME + 16);
            prepareAck(msg);
        }
        else if(action == RX_ACK) {
            macState = RX_ACK;
        }
        else if(action == RX) {
            macState = RX;
            checkCounter = 0;
            call Timer.start(DATA_DETECT_TIME);
        }
        else if(action == SLEEP) {
            macState = SLEEP;
            if(isFlagSet(&flags, RESUME_BACKOFF)) {
                if(nav > restLaufzeit) {
                    sdDebug(40);
                    sdDebug(restLaufzeit);
                    restLaufzeit += nav;
                }
                sdDebug(41);
                sdDebug(restLaufzeit);
            }
            else {
                setFlag(&flags, RESUME_BACKOFF);
                restLaufzeit = call Random.rand16() & ZERO_BACKOFF_MASK;
                sdDebug(42);
                sdDebug(restLaufzeit);
            }
            setSleepMode();
        }
        else if(action == INIT) {
            clearFlag(&flags, UNHANDLED_PACKET);
        }
        else {
            // sdDebug(207);
        }
#ifdef SPECKMAC_PERFORMANCE
        if(error == SUCCESS) {
            rxStat.type = getHeader(msg)->type;
            rxStat.from = getHeader(msg)->src;
            rxStat.to = getHeader(msg)->dest;
            rxStat.token = getHeader(msg)->token;
            if(!isControl(msg)) rxStat.repCounter  = ((red_mac_header_t*)payload)->repetitionCounter;
            rxStat.payloadLength = len;
            rxStat.strength = rssiValue;
            rxStat.creationTime = getMetadata(msg)->time;
            call Performance.macRxStats(&rxStat);
        }
#endif
        return m;
    }

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
        if(macState == TX) {
            if(prepareRepetition()) {
                call PacketSend.send(txBufPtr, txLen);
            }
            else {
                macState = RX_ACK;
                setRxMode();
                call Timer.start(RX_ACK_TIMEOUT);
                // sdDebug(220);
                checkCounter = 0;
            }
        }
        else if(macState == TX_ACK) {
            checkCounter = 0;
            macState = RX;
            setRxMode();
            // sdDebug(221);
#ifdef SPECKMAC_DEBUG            
            // sdDebug(40000U + repCounter);
#endif
        }
    }
    
    /***** TimeStamping stuff **************************/
    async event void RadioTimeStamping.receivedSFD( uint16_t time ) {
        if(call RssiAdcResource.isOwner()) call ChannelMonitorData.getSnr();
        if(macState == RX_P) {
            rxTime = call LocalTime32kHz.get();
            call ChannelMonitor.rxSuccess();
        }
    }
    
    async event void RadioTimeStamping.transmittedSFD(uint16_t time, message_t* p_msg ) {
        if((macState == TX) && (p_msg == txBufPtr)) {
            txMacHdr->time =
                call TimeDiff32.computeDelta(call LocalTime32kHz.get(), getMetadata(p_msg)->time);
        }
    }
    
    /****** Timer ******************************/

    void checkOnBusy() {
        setFlag(&flags, ACTION_DETECTED);
        if((macState == RX) || (macState == CCA) || (macState == CCA_ACK)) {
            if(macState == CCA) {
                sdDebug(101);
                computeBackoff();
#ifdef SPECKMAC_PERFORMANCE
                call Performance.macBusyOnCca();
#endif
            }
            requestAdc();
            // sdDebug(230);
            macState = RX;
            checkCounter = 0;
            call Timer.start(TX_GAP_TIME>>1);
        }
    }

    void checkOnIdle()  {
        if(macState == RX) {
            // sdDebug(240);
            checkCounter++;
            if(checkCounter < 2) {
                call Timer.start(DATA_DETECT_TIME);
                requestAdc();
            } else {
                macState = SLEEP;
                setSleepMode();
            }
        }
        else if(macState == CCA) {
            checkCounter++;
            if(checkCounter < 3) {
                // sdDebug(242);                
                call Timer.start(TX_GAP_TIME >> 1);
                requestAdc();
            }
            else {
                // sdDebug(243);
                macState = TX;
                setTxMode();
#ifdef SPECKMAC_PERFORMANCE
                call Performance.macIdleOnCca();
                txStat.txModeTime = call LocalTime32kHz.get();
#endif
            }
        }
    }
    
    async event void Timer.fired() {
        // sdDebug(250);
        if((macState == RX) || (macState == CCA) || (macState == CCA_ACK)) {
            if((!call RssiAdcResource.isOwner()) || (call ChannelMonitor.start() != SUCCESS)) {
                if(call UartPhyControl.isBusy()) {
                    // sdDebug(251);
                    checkOnBusy();
                }
                else {
                    // sdDebug(252);
                    checkOnIdle();
                }
            }
        }
        else if(macState == RX_ACK) {
            if(needsAckTx(txBufPtr)) {
                // sdDebug(254);
#ifdef SPECKMAC_PERFORMANCE
                call Performance.macAckTimeout();
#endif
                updateLongRetryCounters();
            }
            else {
                // sdDebug(255);
                signalSendDone(SUCCESS);
            }
            macState = SLEEP;
            setSleepMode();
        }
        else if(macState == TX_ACK) {
            setTxMode();
            // sdDebug(10000 + getHeader(&ackMsg)->dest);
        }
        else if(macState == SLEEP) {
             if(isFlagSet(&flags, SWITCHING)) {
                 // sdDebug(256);
                 call Timer.start(call Random.rand16() & 0x0f);
             }
             else {
                 if(isFlagSet(&flags, RESUME_BACKOFF)) {
                     // sdDebug(261);
                     clearFlag(&flags, RESUME_BACKOFF);
                     call Timer.start(restLaufzeit);
                     restLaufzeit = 0;
                     sdDebug(50);
                 }
                 else {
                     // sdDebug(262);
                     checkSend();
                 }
             }
        }
        else if((macState == RX_ACK_P) || (macState == RX_P)) {
            // sdDebug(258);
        }
        else if(macState == INIT) {
            // sdDebug(259);
            post StartDoneTask();
        }
        else {
            // sdDebug(260);
        }
    }

    /****** SampleTimer ******************************/

    async event void SampleTimer.fired() {
        call SampleTimer.start(localSleeptime);
        // sdDebug(270);
        if((macState == SLEEP) && (!isFlagSet(&flags, SWITCHING))) {
            clearFlag(&flags, ACTION_DETECTED);
            sdDebug(200);
            interruptBackoffTimer();
            macState = RX;
            // sdDebug(271);
            setRxMode();
            call Timer.stop();
        }
    }

    /***** Sleeptime **********************************/
    async command void Sleeptime.setLocalSleeptime(uint16_t sT) {
        atomic localSleeptime = sT;
    }

    async command uint16_t Sleeptime.getLocalSleeptime() {
        uint16_t st;
        atomic st = localSleeptime;
        return st;        
    }

    async command void Sleeptime.setNetworkSleeptime(uint16_t sT) {
        atomic {
            networkSleeptime = sT;
            for(MIN_BACKOFF_MASK = 1; MIN_BACKOFF_MASK < sT; ) {
                MIN_BACKOFF_MASK = (MIN_BACKOFF_MASK << 1) + 1;
            }
            MIN_BACKOFF_MASK >>= 3;
        }
    }
    
    async command uint16_t Sleeptime.getNetworkSleeptime() {
        uint16_t st;
        atomic st = networkSleeptime;
        return st;
    }

    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
        // sdDebug(280);
        checkOnBusy();
    }

    async event void ChannelMonitor.channelIdle() {
        // sdDebug(281);
        checkOnIdle();
    }

    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
        if(macState == INIT) {
            // sdDebug(290);
            call Timer.start(call Random.rand16() % localSleeptime);
            setSleepMode();
        } else {
            // sdDebug(291);
        }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
        atomic if((macState == RX_P) || (macState == RX_ACK_P)) rssiValue = data;
    }
    
    /***** Rssi Resource events ******************/
    event void RssiAdcResource.granted() {
        macState_t ms;
        atomic ms = macState;
        if(ms < SLEEP) {
            // sdDebug(300);
        }
        else if(ms == INIT) {
            // sdDebug(301);
            call ChannelMonitorControl.updateNoiseFloor();            
        }
        else {
            // sdDebug(302);
            post ReleaseAdcTask();
        }
    }
    
    default async event void ChannelCongestion.congestionEvent(uint8_t level) {}

    /***** unused Radio Modes events **************************/
    
    async event void RadioModes.TimerModeDone() {}
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}
}

