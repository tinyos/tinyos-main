/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
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
 * The Active Message layer for the CC2420 radio with timesync support. This
 * configuration is just layer above CC2420ActiveMessageC that supports
 * TimeSyncPacket and TimeSyncAMSend interfaces (TEP 133)
 *
 * @author: Miklos Maroti
 * @author: Brano Kusy (CC2420 port)
 */

#include <Timer.h>
#include <AM.h>
#include "CC2420TimeSyncMessage.h"

configuration CC2420TimeSyncMessageC
{
    provides
    {
        interface SplitControl;
        interface Receive[am_id_t id];
        interface Receive as Snoop[am_id_t id];
        interface Packet;
        interface AMPacket;
        interface PacketAcknowledgements;
        interface LowPowerListening;
    
        interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

        interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
    }
}

implementation
{
        components CC2420TimeSyncMessageP, CC2420ActiveMessageC, CC2420PacketC, LedsC;

        TimeSyncAMSend32khz = CC2420TimeSyncMessageP;
        TimeSyncPacket32khz = CC2420TimeSyncMessageP;

        TimeSyncAMSendMilli = CC2420TimeSyncMessageP;
        TimeSyncPacketMilli = CC2420TimeSyncMessageP;

        Packet = CC2420TimeSyncMessageP;
        // use the AMSenderC infrastructure to avoid concurrent send clashes
        components new AMSenderC(AM_TIMESYNCMSG);
        CC2420TimeSyncMessageP.SubSend -> AMSenderC;
      	CC2420TimeSyncMessageP.SubAMPacket -> AMSenderC;
        CC2420TimeSyncMessageP.SubPacket -> AMSenderC;

        CC2420TimeSyncMessageP.PacketTimeStamp32khz -> CC2420PacketC;
        CC2420TimeSyncMessageP.PacketTimeStampMilli -> CC2420PacketC;
        CC2420TimeSyncMessageP.PacketTimeSyncOffset -> CC2420PacketC;
        components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
        LocalTime32khzC.Counter -> Counter32khz32C;
        CC2420TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
        CC2420TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;
        CC2420TimeSyncMessageP.Leds -> LedsC;

        components ActiveMessageC;
        SplitControl = CC2420ActiveMessageC;
        PacketAcknowledgements = CC2420ActiveMessageC;
        LowPowerListening = CC2420ActiveMessageC;
        
        Receive = CC2420TimeSyncMessageP.Receive;
        Snoop = CC2420TimeSyncMessageP.Snoop;
        AMPacket = CC2420TimeSyncMessageP;
        CC2420TimeSyncMessageP.SubReceive -> ActiveMessageC.Receive[AM_TIMESYNCMSG];
        CC2420TimeSyncMessageP.SubSnoop -> ActiveMessageC.Snoop[AM_TIMESYNCMSG];
}
