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

 /**
  * An implementation of a Csma Mac.
  * 
  * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
  * @author: Kevin Klues (klues@tkn.tu-berlin.de)
  * @author Philipp Huppertz (huppertz@tkn.tu-berlin.de)
*/
module CsmaMacP {
    provides {
        interface Init;
        interface SplitControl;
        interface MacSend;
        interface MacReceive;
    }
    uses {
        interface StdControl as CcaStdControl;
        interface PhySend as PacketSend;
        interface PhyReceive as PacketReceive;
        
        interface Tda5250Control as RadioModes;  

        interface UartPhyControl;
      
        interface ChannelMonitor;
        interface ChannelMonitorControl;  
        interface ChannelMonitorData;

        interface Random;
        
        interface Alarm<T32khz, uint16_t> as Timer;

        interface GeneralIO as Led0;
        interface GeneralIO as Led1;
        interface GeneralIO as Led2;
        interface GeneralIO as Led3;
    }
}
implementation
{
#define CSMA_ACK 100
#define BYTE_TIME 17
// #define MACM_DEBUG                    // debug...
#define MAX_LONG_RETRY 3              // Missing acks, or short retry limit hits -> increase long retry 
#define MAX_SHORT_RETRY 5             // busy channel -> increase short retry
#define DIFS 165                      // 5ms to get an ACK started
#define ACK_TIMEOUT 20*BYTE_TIME
#define MIN_BACKOFF_MASK 0x7F         // roughly 4ms for Rx/Tx turnaround defines this value
#define CHECK_RX_LIVENESS_INTERVALL 165
    
/**************** Module Global Variables  *****************/
    
    /* state vars & defs */
    typedef enum {
        SW_CCA,          // switch to CCA
        CCA,             // clear channel assessment     
        SW_RX,           // switch to receive
        RX,              // rx mode done, listening & waiting for packet
        SW_RX_ACK,
        RX_ACK,
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
        BUSY_DETECTED_VIA_RSSI = 2,
        CHECK_RX_LIVENESS = 4,
        DIFS_TIMER_FIRED = 8
    } flags_t;

    /* Packet vars */
    message_t* txBufPtr;
    message_t ackMsg;

    uint8_t txLen;
    int16_t rssiValue;
    uint8_t shortRetryCounter;
    uint8_t longRetryCounter;

    macState_t macState;
    uint8_t flags;

    uint16_t slotMask;
    
    /****** debug vars & defs & functions  ***********************/
#ifdef MACM_DEBUG
#define HISTORY_ENTRIES 40
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
//         (macState & 1) ? call Led0.set() : call Led0.clr();
//         (macState & 2) ? call Led1.set() : call Led1.clr();
//         (macState & 4) ? call Led2.set() : call Led2.clr();
//         (macState & 8) ? call Led3.set() : call Led3.clr();
#endif
    }
    
    /****** Secure switching of radio modes ***/
    
    task void SetRxModeTask();
    task void SetTxModeTask();
    
    void setRxMode();
    void setTxMode();

    void setRxMode() {
        if(call RadioModes.RxMode() == FAIL) {
            post SetRxModeTask();
        }
    }
    
    task void SetRxModeTask() {
        atomic {
            if((macState == SW_RX) ||
               (macState == SW_RX_ACK) ||
               (macState == SW_CCA) ||
               (macState == INIT)) setRxMode();
        }
    }

    void setTxMode() {
        clearFlag(&flags, RSSI_STABLE);
        clearFlag(&flags, BUSY_DETECTED_VIA_RSSI);
        if(call RadioModes.TxMode() == FAIL) {
            post SetTxModeTask();
        }
    }
    
    task void SetTxModeTask() {
        atomic {
            if((macState == SW_TX) ||
               (macState == SW_TX_ACK)) setTxMode();
        }
    }

    /**************** Helper functions ********/
    uint16_t backoff() {
        uint16_t mask = slotMask;
        unsigned i;
        for(i = 0; i < longRetryCounter; i++) {
            mask = (mask << 1) + 1;
        }
        return (call Random.rand16() & mask);
    }
    
    void signalSendDone(error_t error) {
        message_t *m;
        atomic {
            m = txBufPtr;
            txBufPtr = 0;
            txLen  = 0;
            longRetryCounter = 0;
            shortRetryCounter = 0;
        }
        signal MacSend.sendDone(m, error);
    }

    void updateRetryCounters() {
        shortRetryCounter++;
        if(shortRetryCounter > MAX_SHORT_RETRY) {
            longRetryCounter++;
            shortRetryCounter = 1;
            if(longRetryCounter > MAX_LONG_RETRY) {
                signalSendDone(FAIL);
            }
        }
    }
    
    void checkSend() {
        if((txBufPtr != NULL) && (macState == RX) && (!call Timer.isRunning())) {
            clearFlag(&flags, CHECK_RX_LIVENESS);
            clearFlag(&flags, DIFS_TIMER_FIRED);
            /*           if(!call UartPhyControl.isBusy()) { */
                if(isFlagSet(&flags, RSSI_STABLE)) {
                    macState = CCA;
                    signalMacState();
                    call Timer.start(DIFS);
                    call ChannelMonitor.start();
                    storeOldState(130);
                } else {
                    macState = SW_CCA;
                    signalMacState();
                    storeOldState(131);
                }
 /*           }
            else {
                storeOldState(132);
                updateRetryCounters();
                setFlag(&flags, CHECK_RX_LIVENESS);
                call Timer.start(backoff());
            }
                */
      }
    }
    
    bool needsAck(message_t* msg) {
        return FALSE;  // (getHeader(msg)->addr != AM_BROADCAST_ADDR);
    }
    
    /**************** Init ************************/
    
    command error_t Init.init(){
        atomic {
            txBufPtr = NULL;
            macState = INIT;
            signalMacState();
            shortRetryCounter = 0;
            longRetryCounter = 0;
            flags = 0;
            slotMask = MIN_BACKOFF_MASK;
#ifdef MACM_DEBUG
            histIndex = 0;
#endif
        }
        return SUCCESS;
    }

    /****************  SplitControl  *****************/

    task void StartDoneTask() {
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
    
    /****** Radio(Mode) events *************************/
    async event void RadioModes.RssiStable() {
        atomic  {
            setFlag(&flags, RSSI_STABLE);
            if(macState == SW_CCA)  {
                storeOldState(10);
                macState = CCA;
                signalMacState();
                call Timer.start(DIFS);
                call ChannelMonitor.start();
            } else if(macState == INIT) {
                storeOldState(11);
                call ChannelMonitorControl.updateNoiseFloor();
            } else {
                storeOldState(13);
            }
        }
    }

    async event void RadioModes.RxModeDone() {
        atomic {
            if(macState == SW_RX) {
                storeOldState(21);
                macState = RX;
                signalMacState();
                call Timer.start(backoff());
            }
            else if(macState == SW_RX_ACK) {
                storeOldState(22);
                macState = RX_ACK;
                signalMacState();
                call Timer.start(ACK_TIMEOUT);
            }
            else if(macState == SW_CCA) {
                storeOldState(23);
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
            if((shortRetryCounter == 0) && (txBufPtr == NULL)) {
                storeOldState(40);
                shortRetryCounter = 1;
                txBufPtr = msg;
                txLen = len;
                if((macState != RX_P) && (macState != RX_ACK)) checkSend();
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
            rssiValue = 0xFFFF;
            call Timer.stop();
            clearFlag(&flags, CHECK_RX_LIVENESS);
            if(isFlagSet(&flags, BUSY_DETECTED_VIA_RSSI)) call ChannelMonitor.rxSuccess();
            call  ChannelMonitorData.getSnr();
        }
        if(macState <= RX) {
            storeOldState(61);
            macState = RX_P;
            signalMacState();
        }
        else if(macState <= RX_ACK) {
            storeOldState(62);
            macState = RX_ACK;
            signalMacState();
        }
        else if(macState == INIT) {
            storeOldState(63);
        }
        else {
            storeOldState(64);
            signalFailure(4);
        } 
    }
    
    async event message_t* PacketReceive.receiveDone(message_t* msg, void* payload, uint8_t len, error_t error) {
        message_t* m = msg;
        if(macState == RX_P) {
            storeOldState(70);
            if (error == SUCCESS) {
                storeOldState(71);
                (getMetadata(msg))->strength = rssiValue;
                m = signal MacReceive.receiveDone(msg);
            }
            macState = RX;
            signalMacState();
            call Timer.start(backoff());
        }
        else if(macState == RX_ACK) {
            storeOldState(72);
            if(txBufPtr == NULL) signalFailure(5);
            if((error == SUCCESS) &&
               getFooter(msg)->crc &&
               (getHeader(msg)->type == CSMA_ACK) &&
               (*((uint16_t*)(msg->data)) == TOS_NODE_ID))
            {
                storeOldState(73);
                getMetadata(txBufPtr)->ack = 1;
                signalSendDone(SUCCESS);
            }
            else {
                storeOldState(74);
                updateRetryCounters();
            }
            macState = RX;
            signalMacState();
            call Timer.start(backoff());
        } else {
            storeOldState(76);
        }
        return m;
    }

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
        if(macState == TX) {
            if(msg != txBufPtr) signalFailure(7);            
            if(needsAck(msg)) {
                if(error == SUCCESS) {
                    storeOldState(80);
                    macState = SW_RX_ACK;
                    signalMacState();
                } else {
                    storeOldState(81);
                    macState = SW_RX;
                    signalMacState();
                }
            } else {
                macState = SW_RX;
                signalMacState();
                signalSendDone(error);
            }
        }
        else if(macState == TX_ACK) {
            storeOldState(83);
            if(msg != &ackMsg) signalFailure(8);
            macState = SW_RX;
            signalMacState();
        }
        else {
            storeOldState(84);
            signalFailure(9);
        }
        setRxMode();
    }
       
    
    /****** Timer ******************************/
    
    async event void Timer.fired() {
        if(macState == RX) {
            storeOldState(90);
            if(isFlagSet(&flags, CHECK_RX_LIVENESS)) {
                /* if(call UartPhyControl.isBusy()) {
                    call Timer.start(CHECK_RX_LIVENESS_INTERVALL);
                }
                else {
                */
                    call ChannelMonitor.start();
                    /*} */
            } else {
                checkSend();
            }
        }
        else if(macState == RX_ACK) {
            storeOldState(91);
            updateRetryCounters();
            macState = RX;
            signalMacState();
            call Timer.start(backoff());
        }
        else if(macState == CCA) {
            storeOldState(92);
            setFlag(&flags, DIFS_TIMER_FIRED);
            call ChannelMonitor.start();
        }
        else {
            storeOldState(93);
            signalFailure(10);
        }
    }
    
    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
        atomic {
            if(macState == CCA) {
                storeOldState(100);
                macState = RX;
                signalMacState();
                setFlag(&flags, BUSY_DETECTED_VIA_RSSI);
                updateRetryCounters();
                call Timer.start(backoff());
            }
            else if(macState == RX_P) {
                storeOldState(101);
                setFlag(&flags, BUSY_DETECTED_VIA_RSSI);
            }
            else if((macState == RX) && (isFlagSet(&flags, CHECK_RX_LIVENESS))) {
                storeOldState(102);
                call Timer.start(CHECK_RX_LIVENESS_INTERVALL);
            }
        }
    }

    async event void ChannelMonitor.channelIdle() {
        storeOldState(110);
        if((macState == RX) && (isFlagSet(&flags, CHECK_RX_LIVENESS))) {
                storeOldState(111);
                clearFlag(&flags, CHECK_RX_LIVENESS);
                call Timer.start(backoff());
        }
        else if(macState == CCA) {
          if(isFlagSet(&flags, DIFS_TIMER_FIRED)) {    
            clearFlag(&flags, DIFS_TIMER_FIRED);
            storeOldState(112);
            macState = SW_TX;
            signalMacState();
            setTxMode();
          }
        }
    }


    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
        if(macState == INIT) {
            storeOldState(120);
            macState = RX;
            signalMacState();
            post StartDoneTask();
        } else {
            storeOldState(121);
            signalFailure(11);
        }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
        atomic if(macState == RX_P) rssiValue = data;
    }

    
    /***** unused Radio Modes events **************************/
    
    async event void RadioModes.TimerModeDone() {}
    async event void RadioModes.SleepModeDone() {}
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}
}

