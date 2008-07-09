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
        interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    }
    uses {
        interface LocalTime<TMilli> as LocalTimeMilli;
    }
}
implementation  {
    async command bool PacketTimeStamp32khz.isValid(message_t* msg) {
        return TRUE;
    }
    async command void PacketTimeStamp32khz.clear(message_t* msg) {
    }
    async command uint32_t PacketTimeStamp32khz.timestamp(message_t* msg) {
        return getMetadata(msg)->time;
    }
    async command void PacketTimeStamp32khz.set(message_t* msg, uint32_t value) {
        getMetadata(msg)->time = value;
    }
    async command bool PacketTimeStampMilli.isValid(message_t* msg) {
        return TRUE;
    }
    async command void PacketTimeStampMilli.clear(message_t* msg) {
    }
    async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg) {
        uint32_t now = call LocalTimeMilli.get();
        uint32_t delay = (now * 32) - (getMetadata(msg)->time);
        return now - (delay / 32);
    }
    async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value) {
        getMetadata(msg)->time = value * 32;
    }
}

