/*
 * Copyright (c) 2002, Vanderbilt University
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
 *
 * @author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Ported to T2: 3/17/08 by Brano Kusy (branislav.kusy@gmail.com)
 */

#include "TestFTSP.h"
#include "RadioCountToLeds.h"

module TestFTSPAppC
{
    uses
    {
        interface GlobalTime<TMilli>;
        interface TimeSyncInfo;
        interface Receive;
        interface AMSend;
        interface Packet;
        interface Leds;
        interface PacketTimeStamp<TMilli,uint32_t>;
        interface Boot;
        interface SplitControl as RadioControl;
    }
}

implementation
{
    message_t msg;
    bool locked = FALSE;

    event void Boot.booted() {
        call RadioControl.start();
    }

    event message_t* Receive.receive(message_t* msgPtr, void* payload, uint8_t len)
    {
        call Leds.led0Toggle();
        if (!locked && call PacketTimeStamp.isValid(msgPtr)) {
            radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(msgPtr, sizeof(radio_count_msg_t));
            test_ftsp_msg_t* report = (test_ftsp_msg_t*)call Packet.getPayload(&msg, sizeof(test_ftsp_msg_t));

            uint32_t rxTimestamp = call PacketTimeStamp.timestamp(msgPtr);

            report->src_addr = TOS_NODE_ID;
            report->counter = rcm->counter;
            report->local_rx_timestamp = rxTimestamp;
            report->is_synced = call GlobalTime.local2Global(&rxTimestamp);
            report->global_rx_timestamp = rxTimestamp;
            report->skew_times_1000000 = (uint32_t)call TimeSyncInfo.getSkew()*1000000UL;
            report->ftsp_root_addr = call TimeSyncInfo.getRootID();
            report->ftsp_seq = call TimeSyncInfo.getSeqNum();
            report->ftsp_table_entries = call TimeSyncInfo.getNumEntries();

            if (call AMSend.send(AM_BROADCAST_ADDR, &msg, sizeof(test_ftsp_msg_t)) == SUCCESS) {
              locked = TRUE;
            }
        }

        return msgPtr;
    }

    event void AMSend.sendDone(message_t* ptr, error_t success) {
        locked = FALSE;
        return;
    }

    event void RadioControl.startDone(error_t err) {}
    event void RadioControl.stopDone(error_t error){}
}
