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
 * The Active Message layer for the CC2420 radio with timesync support. This
 * configuration is just layer above CC2420ActiveMessageC that supports
 * TimeSyncPacket and TimeSyncAMSend interfaces (TEP 133)
 *
 * @author: Miklos Maroti
 * @author: Brano Kusy (CC2420 port)
 */

#include <Timer.h>
#include <AM.h>

configuration CC2520TimeSyncMessageC
{
    provides
    {
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

implementation
{
        components CC2520TimeSyncMessageP, CC2520ActiveMessageC, CC2520PacketC, LedsC;

        TimeSyncAMSend32khz = CC2520TimeSyncMessageP;
        TimeSyncPacket32khz = CC2520TimeSyncMessageP;

        TimeSyncAMSendMilli = CC2520TimeSyncMessageP;
        TimeSyncPacketMilli = CC2520TimeSyncMessageP;

        Packet = CC2520TimeSyncMessageP;
        CC2520TimeSyncMessageP.SubSend -> CC2520ActiveMessageC.AMSend;
        CC2520TimeSyncMessageP.SubPacket -> CC2520ActiveMessageC.Packet;

        CC2520TimeSyncMessageP.PacketTimeStamp32khz -> CC2520PacketC;
        CC2520TimeSyncMessageP.PacketTimeStampMilli -> CC2520PacketC;
        CC2520TimeSyncMessageP.PacketTimeSyncOffset -> CC2520PacketC;
        components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
        LocalTime32khzC.Counter -> Counter32khz32C;
        CC2520TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
        CC2520TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;
        CC2520TimeSyncMessageP.Leds -> LedsC;

        SplitControl = CC2520ActiveMessageC;
        Receive = CC2520ActiveMessageC.Receive;
        Snoop = CC2520ActiveMessageC.Snoop;
        AMPacket = CC2520ActiveMessageC;
}
