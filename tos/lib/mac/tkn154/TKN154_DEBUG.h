/*
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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2008-11-25 09:35:09 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_DEBUG_H
#define __TKN154_DEBUG_H

#define PollP_ALLOC_FAIL1     0
#define PollP_ALLOC_FAIL2     1
#define PollP_INTERNAL_POLL   2
#define PollP_SUCCESS         3
#define PollP_TXDONE          4
#define PollP_WRONG_FORMAT    5
#define PollP_INTERNAL_ERROR  6
#define PollP_RX              7

#define IndirectTxP_OVERFLOW      0
#define IndirectTxP_NOTIFIED      1
#define IndirectTxP_REQUESTED     2
#define IndirectTxP_BUSY          3
#define IndirectTxP_DATA_REQUEST  4
#define IndirectTxP_SEND_NOW      5
#define IndirectTxP_SEND_NOW_FAIL 6
#define IndirectTxP_SEND_DONE     7
#define IndirectTxP_BEACON_ASSEMBLY 8

#define EnableRxP_RADIORX_ERROR       0
#define EnableRxP_PROMISCUOUS_REQUEST 1
#define EnableRxP_PROMISCUOUS_ON      2
#define EnableRxP_PROMISCUOUS_OFF     3

#define AssociateP_REQUEST        0
#define AssociateP_TXDONE         1
#define AssociateP_TIMEOUT        2
#define AssociateP_RX             3
#define AssociateP_SETTIMER       4
#define AssociateP_POLL_DONE      5

#define DISSASSOCIATE_REQUEST        50
#define DISSASSOCIATE_TXDONE         51
#define DISSASSOCIATE_RX             52

#define CapP_TOO_SHORT           0
#define CapP_SET_CAP_END         1
#define CapP_CAP_END_FIRED       2
#define CapP_INTERNAL_ERROR      3

#define DeviceCapTransmitP_CONTINUE           0
#define DeviceCapTransmitP_TOVERFLOW          1
#define DeviceCapTransmitP_RADIO_RESERVE      2
#define DeviceCapTransmitP_CCA_FAIL           3
#define DeviceCapTransmitP_NO_ACK             4
#define DeviceCapTransmitP_TX_DONE            5
#define DeviceCapTransmitP_TX_PREPARE         6
#define DeviceCapTransmitP_TX_NOW             7
#define DeviceCapTransmitP_TX_CANCEL          8
#define DeviceCapTransmitP_TX_PREPARE_DONE    9
#define DeviceCapTransmitP_CAP_END_ALARM     10
#define DeviceCapTransmitP_RADIO_OFF         11
#define DeviceCapTransmitP_RADIO_RX          12
#define DeviceCapTransmitP_TX_CANCEL_DONE    13
#define DeviceCapTransmitP_TX_DONE_UNKNOWN   14
#define DeviceCapTransmitP_RESOURCE_REQ      15
#define DeviceCapTransmitP_GOT_RESOURCE      16

#define CoordCapTransmitP_RADIO_RESERVE      0
#define CoordCapTransmitP_TX_CANCEL          1
#define CoordCapTransmitP_CCA_FAIL           2
#define CoordCapTransmitP_CAP_END_ALARM      3
#define CoordCapTransmitP_OFF_DONE           4
#define CoordCapTransmitP_FINISH_TX          5
#define CoordCapTransmitP_RADIO_RX           6


#define PhyRx_START 0
#define PhyRx_STOP 1
#define PhyRx_FIFOP    2
#define PhyRx_RXON 3


enum {
  DEBUG_LEVEL_INFO = 0,
  DEBUG_LEVEL_IMPORTANT = 1,
  DEBUG_LEVEL_CRITICAL = 2,

  // IDs assigned for debugging
  DEBUG_BEACON_TRANSMIT_ID = 0,
  DEBUG_FRAME_DISPATCH_COORD_ID = 1,
  DEBUG_COORD_CFP_ID = 2,

  DEBUG_BEACON_SYNCHRONIZE_ID = 3,
  DEBUG_FRAME_DISPATCH_DEVICE_ID = 4,
  DEBUG_DEVICE_CFP_ID = 5,

  DEBUG_SCAN_ID = 6,

  DEBUG_RADIOCONTROL_ID = 7,
  DEBUG_PIB_ID = 8,
  DEBUG_ASSOCIATE_ID = 9,
  DEBUG_DISASSOCIATE_ID = 10,
  DEBUG_FRAMEDISPATCHQUEUE_ID = 11,
  DEBUG_INDIRECTTX_ID = 12,
  DEBUG_DATA_ID = 13,
  DEBUG_POLL_ID = 14,
  DEBUG_RXENABLE_ID = 15,
  DEBUG_PROMISCUOUSMODE_ID = 16,
  DEBUG_RADIO_DRIVER_ID = 17,

};

typedef nx_struct serial_debug_msg {
  nx_uint8_t client; 
  nx_uint8_t eventID;
  nx_uint8_t seqno;
  nx_uint8_t priority;
  nx_uint32_t timestamp;
  nx_uint32_t param1; 
  nx_uint32_t param2; 
  nx_uint32_t param3;
} serial_debug_msg_t;

#ifndef SERIAL_DBG_MSGBUF_SIZE
#define SERIAL_DBG_MSGBUF_SIZE  150
#endif

enum {
  AM_SERIAL_DEBUG_MSG = 222,
};

#endif // __TKN154_DEBUG_H
