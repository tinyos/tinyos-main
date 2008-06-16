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
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:00:29 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_DEBUG_H
#define __TKN154_DEBUG_H

#define LEVEL_INFO 0
#define LEVEL_IMPORTANT 50
#define LEVEL_CRITICAL 100

#define RadioRxTxP_ACQUIRED         0
#define RadioRxTxP_NOT_ACQUIRED     1
#define RadioRxTxP_TRANSFERRED      2
#define RadioRxTxP_NOT_TRANSFERRED  3
#define RadioRxTxP_RELEASED         4
#define RadioRxTxP_NOT_RELEASED     5
#define RadioRxTxP_TRANSFER_REQUEST 6
#define RadioRxTxP_DEFAULT_PREPARE_TX_DONE 7
#define RadioRxTxP_DEFAULT_TX_DONE         8
#define RadioRxTxP_DEFAULT_PREPARE_RX_DONE 9
#define RadioRxTxP_DEFAULT_RECEIVED        10
#define RadioRxTxP_DEFAULT_OFFDONE         11
#define RadioRxTxP_DEFAULT_TRANSFERRED     12 
#define RadioRxTxP_DEFAULT_TRANSFERREQUEST 13
#define RadioRxTxP_ASK_ISOWNER             14
#define RadioRxTxP_RX_NOOWNER              15
#define RadioRxTxP_DEFAULT_CANCEL_TX_DONE  16
#define RadioRxTxP_DEFAULT_CANCEL_RX_DONE  17

#define SyncP_BEACON_MISSED_1 0
#define SyncP_BEACON_MISSED_2 1
#define SyncP_BEACON_MISSED_3 2
#define SyncP_TRACK_ALARM     3
#define SyncP_INVALID_PARAM   4
#define SyncP_RX_ON           5
#define SyncP_INTERNAL_ERROR  6
#define SyncP_BEACON_RX       7
#define SyncP_RADIO_BUSY      8
#define SyncP_LOST_SYNC       9
#define SyncP_RX_PACKET       10
#define SyncP_NEXT_RX_TIME    11
#define SyncP_SWITCHOFF       12
#define SyncP_RX_GARBAGE      13
#define SyncP_GOT_RESOURCE    14
#define SyncP_RELEASE_RESOURCE 15
#define SyncP_RESOURCE_REQUEST  16
#define SyncP_TRANSFER_RESOURCE 17
#define SyncP_PREPARE_RX      18
#define SyncP_REQUEST  19
#define SyncP_UPDATING  20
#define SyncP_PREPARE_RX_DONE     21
#define SyncP_INVALID_TIMESTAMP     22
#define SyncP_RX_BEACON       SyncP_RX_PACKET

#define StartP_BEACON_TRANSMITTED 0
#define StartP_UPDATE_STATE   1
#define StartP_REQUEST        2
#define StartP_OWNER_TOO_FAST 3
#define StartP_BEACON_UPDATE  4
#define StartP_BEACON_UPDATE_2 5
#define StartP_PREPARE_TX     6
#define StartP_PREPARE_TXDONE 7
#define StartP_SKIPPED_BEACON    8
#define StartP_GOT_RESOURCE    9
#define StartP_TRANSMIT    10

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

#define Phy_RX_CANCEL      0
#define Phy_RX_NOW         1
#define Phy_LOAD_TX_FIFO   2
#define Phy_LOAD_TX_FIFO_DONE 3
#define Phy_LOAD_TX_CANCEL 4
#define Phy_LOAD_TX_NOW 5
#define Phy_LOAD_TX_RX_NOW 6
#define Phy_SEND_DONE 7
#define Phy_SPI_GRANTED 8
#define Phy_RADIO_OFF 9
#define Phy_RADIO_OFF_DONE 10
#define Phy_RADIO_PREPARE_RX 11
#define Phy_RADIO_PREPARE_TX 12
#define Phy_RADIO_TX_DONE 13
#define Phy_RADIO_RECEIVED 14

#define PhyRx_START 0
#define PhyRx_STOP 1
#define PhyRx_FIFOP    2
#define PhyRx_RXON 3

enum {
  // IDs assigned for debugging
  START_CLIENT = 0,
  COORD_CAP_CLIENT = 1,
  COORD_CFP_CLIENT = 2,

  SYNC_CLIENT = 3,
  DEVICE_CAP_CLIENT = 4,
  DEVICE_CFP_CLIENT = 5,

  SCAN_CLIENT = 6,

  RADIORXTX_CLIENT = 7,
  PIBDATABASE_CLIENT = 8,
  ASSOCIATE_CLIENT = 9,
  DEVICECAPQUEUE_CLIENT = 10,
  INDIRECTTX_DEBUG_CLIENT = 11,
  DATA_CLIENT = 12,
  POLL_CLIENT = 13,
  DISASSOCIATE_CLIENT = 14,
  RXENABLE_CLIENT = 15,

  PHY_CLIENT = 16,
  PHY_TXCLIENT = 17,
  PHY_RXCLIENT = 18,
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
#define SERIAL_DBG_MSGBUF_SIZE 25
#endif

enum {
  AM_SERIAL_DEBUG_MSG = 222,
};

#endif // __TKN154_DEBUG_H
