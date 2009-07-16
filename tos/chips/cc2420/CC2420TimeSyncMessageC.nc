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

configuration CC2420TimeSyncMessageC
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
        components CC2420TimeSyncMessageP, CC2420ActiveMessageC, CC2420PacketC, LedsC;

        TimeSyncAMSend32khz = CC2420TimeSyncMessageP;
        TimeSyncPacket32khz = CC2420TimeSyncMessageP;

        TimeSyncAMSendMilli = CC2420TimeSyncMessageP;
        TimeSyncPacketMilli = CC2420TimeSyncMessageP;

        Packet = CC2420TimeSyncMessageP;
        // use the AMSenderC infrastructure to avoid concurrent send clashes
        components AMQueueP, ActiveMessageC;
        CC2420TimeSyncMessageP.SubSend -> AMQueueP.Send[unique(UQ_AMQUEUE_SEND)];
        CC2420TimeSyncMessageP.AMPacket -> ActiveMessageC;
        CC2420TimeSyncMessageP.SubPacket -> ActiveMessageC;

        CC2420TimeSyncMessageP.PacketTimeStamp32khz -> CC2420PacketC;
        CC2420TimeSyncMessageP.PacketTimeStampMilli -> CC2420PacketC;
        CC2420TimeSyncMessageP.PacketTimeSyncOffset -> CC2420PacketC;
        components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
        LocalTime32khzC.Counter -> Counter32khz32C;
        CC2420TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
        CC2420TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;
        CC2420TimeSyncMessageP.Leds -> LedsC;

        SplitControl = CC2420ActiveMessageC;
        Receive = CC2420ActiveMessageC.Receive;
        Snoop = CC2420ActiveMessageC.Snoop;
        AMPacket = CC2420ActiveMessageC;
}
