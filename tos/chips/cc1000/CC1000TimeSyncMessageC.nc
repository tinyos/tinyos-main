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
 * The Active Message layer for the CC1000 radio with timesync support. This
 * configuration is just layer above CC1000ActiveMessageC that supports
 * TimeSyncPacket and TimeSyncAMSend interfaces (TEP 133)
 *
 * @author: Miklos Maroti
 * @author: Brano Kusy (CC2420 port)
 * @author: Marco Langerwisch (CC1000 port)
 */

#include <Timer.h>
#include <AM.h>

configuration CC1000TimeSyncMessageC
{
    provides
    {
        interface SplitControl;
        interface Receive[am_id_t id];
        interface Receive as Snoop[am_id_t id];
        interface Packet;
        interface AMPacket;

        interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
        interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

        interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

        interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
    }
}

implementation
{
        components CC1000TimeSyncMessageP, CC1000ActiveMessageC, LedsC;

        PacketTimeStamp32khz = CC1000ActiveMessageC;
        PacketTimeStampMilli = CC1000ActiveMessageC;

        TimeSyncAMSend32khz = CC1000TimeSyncMessageP;
        TimeSyncPacket32khz = CC1000TimeSyncMessageP;

        TimeSyncAMSendMilli = CC1000TimeSyncMessageP;
        TimeSyncPacketMilli = CC1000TimeSyncMessageP;

        Packet = CC1000TimeSyncMessageP;
        CC1000TimeSyncMessageP.SubSend -> CC1000ActiveMessageC.AMSend;
        CC1000TimeSyncMessageP.SubPacket -> CC1000ActiveMessageC.Packet;
        CC1000TimeSyncMessageP.PacketTimeStamp32khz -> CC1000ActiveMessageC;
        CC1000TimeSyncMessageP.PacketTimeStampMilli -> CC1000ActiveMessageC;
        CC1000TimeSyncMessageP.PacketTimeSyncOffset -> CC1000ActiveMessageC;

        components Counter32khz32C,
            new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
        LocalTime32khzC.Counter -> Counter32khz32C;
        CC1000TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
        CC1000TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;
        CC1000TimeSyncMessageP.Leds -> LedsC;

        SplitControl = CC1000ActiveMessageC;
        Receive = CC1000ActiveMessageC.Receive;
        Snoop = CC1000ActiveMessageC.Snoop;
        AMPacket = CC1000ActiveMessageC;
}
