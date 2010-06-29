/*
 * Copyright (c) 2002, Vanderbilt University
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
 *
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 * Ported for LPL: Thomas Schmid (thomas.schmid@ucla.edu)
 */

#include "TestFtsp.h"
#include "RadioCountToLeds.h"

module TestFtspC
{
    uses
    {
        interface GlobalTime<T32khz>;
        interface TimeSyncInfo;
        interface Receive;
        interface AMSend;
        interface Packet;
        interface Leds;
        interface PacketTimeStamp<T32khz,uint32_t>;
        interface Boot;
        interface SplitControl as RadioControl;
        interface Timer<TMilli> as RandomTimer;
        interface Random;

        interface TimeSyncPacket<T32khz,uint32_t>;

        interface LowPowerListening;

    }
}

implementation
{
    enum {
        ACT_TESTFTSP = 0x11,
    };

    message_t msg;
    bool locked = FALSE;
    test_ftsp_msg_t* report;

    event void Boot.booted() {
        call RadioControl.start();
    }

    event message_t* Receive.receive(message_t* msgPtr, void* payload, uint8_t len)
    {
        if (!(call PacketTimeStamp.isValid(msgPtr))){
            call Leds.led1Toggle();
        }
        if (!locked && call PacketTimeStamp.isValid(msgPtr)) {
            radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(msgPtr, sizeof(radio_count_msg_t));
            if(call TimeSyncPacket.isValid(msgPtr)) {
                uint32_t rxTimestamp = call TimeSyncPacket.eventTime(msgPtr);
                report = (test_ftsp_msg_t*)call Packet.getPayload(&msg, sizeof(test_ftsp_msg_t));

                report->src_addr = TOS_NODE_ID;
                report->counter = rcm->counter;
                report->local_rx_timestamp = rxTimestamp;
                report->is_synced = call GlobalTime.local2Global(&rxTimestamp);
                report->global_rx_timestamp = rxTimestamp;
                report->skew_times_1000000 = (uint32_t)call TimeSyncInfo.getSkew()*1000000UL;
                report->skew = call TimeSyncInfo.getSkew();
                report->ftsp_root_addr = call TimeSyncInfo.getRootID();
                report->ftsp_seq = call TimeSyncInfo.getSeqNum();
                report->ftsp_table_entries = call TimeSyncInfo.getNumEntries();
                report->localAverage = call TimeSyncInfo.getSyncPoint();
                report->offsetAverage = call TimeSyncInfo.getOffset();

                locked = TRUE;
                call RandomTimer.startOneShot(call Random.rand16() % (64));
            }
        }

        return msgPtr;
    }

    event void RandomTimer.fired()
    {
#ifdef LOW_POWER_LISTENING
        call LowPowerListening.setRemoteWakeupInterval(&msg, LPL_INTERVAL);
#endif
        if(locked && (call AMSend.send(4000, &msg, sizeof(test_ftsp_msg_t)) == SUCCESS)){
            call Leds.led2On();
        } else {
            locked = FALSE;
        }
    }

    event void AMSend.sendDone(message_t* ptr, error_t success) {
        locked = FALSE;
        call Leds.led2Off();
        return;
    }

    event void RadioControl.startDone(error_t err) {
        call LowPowerListening.setLocalWakeupInterval(LPL_INTERVAL);
    }
    event void RadioControl.stopDone(error_t error){}
}
