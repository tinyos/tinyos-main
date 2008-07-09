/* -*- mode:c++; indent-tabs-mode:nil -*- 
 * Copyright (c) 2008, Technische Universitaet Berlin
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
 */

/**
 * Expose the time sync capabilities of the eyesIFX platform 
 */
#include "radiopacketfunctions.h"

module TimeSyncMessageP {
    provides {
        interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

        interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
    }
    uses {
        interface AMSend as SubSend[am_id_t id];
        interface AMPacket;
    }
}
implementation {
    typedef enum 
    {
        NONE,
        RES_32_K,
        RES_1_K
    } resolution_t;

    resolution_t resolution = NONE;
    
    command error_t TimeSyncAMSend32khz.send[am_id_t id](am_addr_t addr,
                                                         message_t* msg,
                                                         uint8_t len,
                                                         uint32_t event_time) {
        getMetadata(msg)->time = event_time;
        resolution = RES_32_K;
        return call SubSend.send[id](addr, msg, len);
    }
    
    command error_t TimeSyncAMSend32khz.cancel[am_id_t id](message_t* msg) {
        return call SubSend.cancel[id](msg);
    }
    
    command uint8_t TimeSyncAMSend32khz.maxPayloadLength[am_id_t id]() {
        return call SubSend.maxPayloadLength[id]();
    }
    
    command void* TimeSyncAMSend32khz.getPayload[am_id_t id](message_t* m, uint8_t len) {
        return call SubSend.getPayload[id](m, len);
    }


    command bool TimeSyncPacket32khz.isValid(message_t* msg) {
        return TRUE;
    }
    
    command uint32_t TimeSyncPacket32khz.eventTime(message_t* msg) {
        return getMetadata(msg)->time;
    };
    
    command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr,
                                                         message_t* msg,
                                                         uint8_t len,
                                                         uint32_t event_time) {
        getMetadata(msg)->time = (event_time * 32);
        resolution = RES_1_K;
        return call SubSend.send[id](addr, msg, len);
    }
    
    command error_t TimeSyncAMSendMilli.cancel[am_id_t id](message_t* msg) {
        return call SubSend.cancel[id](msg);
    }
    
    command uint8_t TimeSyncAMSendMilli.maxPayloadLength[am_id_t id]() {
        return call SubSend.maxPayloadLength[id]();
    }
    
    command void* TimeSyncAMSendMilli.getPayload[am_id_t id](message_t* m, uint8_t len) {
        return call SubSend.getPayload[id](m, len);
    }

    command bool TimeSyncPacketMilli.isValid(message_t* msg) {
        return TRUE;
    }
    
    command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg) {
        return (getMetadata(msg)->time / 32);
    };

    event void SubSend.sendDone[uint8_t id](message_t* msg, error_t result) {
        if(resolution == RES_32_K) {
            signal TimeSyncAMSend32khz.sendDone[id](msg, result);
        }
        else {
            signal TimeSyncAMSendMilli.sendDone[id](msg, result);
        }
    }

    default event void TimeSyncAMSend32khz.sendDone[uint8_t id](message_t* msg, error_t err) {
        return;
    }
    default event void TimeSyncAMSendMilli.sendDone[uint8_t id](message_t* msg, error_t err) {
        return;
    }
}

