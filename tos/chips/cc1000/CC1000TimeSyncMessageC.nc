/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
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
