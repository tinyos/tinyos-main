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
configuration TimeSyncMessageC {
  provides {
    interface SplitControl;
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface Packet;
    interface AMPacket;

    interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
    interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

    interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
    interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
  }
}
implementation {
    components TimeSyncMessageP as TS;
    components ActiveMessageC as AM;
    components PacketStampC as PS;
    
    SplitControl = AM;

    Receive      = AM.Receive;
    Snoop        = AM.Snoop;
    Packet       = AM;
    AMPacket     = AM;
    
    TS.SubSend -> AM.AMSend;
    TS.AMPacket -> AM.AMPacket;

    TS.PacketTimeStamp32khz -> PS;
    TS.PacketTimeStampMilli -> PS;
    
    TimeSyncAMSend32khz       = TS;
    TimeSyncAMSendMilli       = TS;
    TimeSyncPacket32khz       = TS;
    TimeSyncPacketMilli       = TS;
}
