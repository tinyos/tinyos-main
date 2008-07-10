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

#include "radiopacketfunctions.h"

module PacketStampP {
    provides {  
        interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;
        
        interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
    }
    uses {
        interface LocalTime<TMilli> as LocalTimeMilli;
        interface LocalTime<T32khz> as LocalTime32khz;
    }
}
implementation  {
    // 32 kHz interface
    // get the time when SFD event was generated
    async command uint32_t PacketTimeStamp32khz.timestamp(message_t* msg) {
        return getMetadata(msg)->sfdtime;
    }
    // set the time when SFD event was generated?
    async command void PacketTimeStamp32khz.set(message_t* msg, uint32_t value) {
        getMetadata(msg)->sfdtime = value;
    }
    // return time when event was generated at the source
    command uint32_t TimeSyncPacket32khz.eventTime(message_t* msg) {
        return getMetadata(msg)->time;
    };
    
    // Milli interface
    // get the time when SFD was send/received
    async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg) {
        return call LocalTimeMilli.get() -
            (call LocalTime32khz.get() - getMetadata(msg)->sfdtime)/32;
    }
    // set the time when SFD was send/received?
    async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value) {
        getMetadata(msg)->sfdtime =
            call LocalTime32khz.get() - (call LocalTimeMilli.get() - value)*32;
    }
    // return time when event was generated
    command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg) {
        return call LocalTimeMilli.get() -
            (call LocalTime32khz.get() - getMetadata(msg)->time)/32;        
    };

    // not really supported functions, valid section
    command bool TimeSyncPacket32khz.isValid(message_t* msg) {
        return TRUE;
    }
    command bool TimeSyncPacketMilli.isValid(message_t* msg) {
        return TRUE;
    }
    async command bool PacketTimeStamp32khz.isValid(message_t* msg) {
        return TRUE;
    }
    async command bool PacketTimeStampMilli.isValid(message_t* msg) {
        return TRUE;
    }
    
    // not really supported functions, clear section
    async command void PacketTimeStamp32khz.clear(message_t* msg) {
    }
    async command void PacketTimeStampMilli.clear(message_t* msg) {
    }
}

