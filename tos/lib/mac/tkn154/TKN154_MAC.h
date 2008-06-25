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
 * $Date: 2008-06-25 10:19:03 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_MAC_H
#define __TKN154_MAC_H

#include "TKN154.h"
#include "TKN154_PHY.h"

/****************************************************
 * IEEE 802.15.4 PAN information base identifiers
 **/

enum {
  // PHY Sublayer PIB
  IEEE154_phyCurrentChannel          = 0x00,
  IEEE154_phyChannelsSupported       = 0x01,
  IEEE154_phyTransmitPower           = 0x02,
  IEEE154_phyCCAMode                 = 0x03,
  IEEE154_phyCurrentPage             = 0x04,
  IEEE154_phyMaxFrameDuration        = 0x05,
  IEEE154_phySHRDuration             = 0x06,
  IEEE154_phySymbolsPerOctet         = 0x07,

  // MAC Sublayer PIB
  IEEE154_macAckWaitDuration         = 0x40,
  IEEE154_macAssociatedPANCoord      = 0x56,
  IEEE154_macAssociationPermit       = 0x41,
  IEEE154_macAutoRequest             = 0x42,
  IEEE154_macBattLifeExt             = 0x43,
  IEEE154_macBattLifeExtPeriods      = 0x44,
  IEEE154_macBeaconPayload           = 0x45,
  IEEE154_macBeaconPayloadLength     = 0x46,
  IEEE154_macBeaconOrder             = 0x47,
  IEEE154_macBeaconTxTime            = 0x48,
  IEEE154_macBSN                     = 0x49,
  IEEE154_macCoordExtendedAddress    = 0x4A,
  IEEE154_macCoordShortAddress       = 0x4B,
  IEEE154_macDSN                     = 0x4C,
  IEEE154_macGTSPermit               = 0x4D,
  IEEE154_macMaxBE                   = 0x57,
  IEEE154_macMaxCSMABackoffs         = 0x4E,
  IEEE154_macMaxFrameTotalWaitTime   = 0x58,
  IEEE154_macMaxFrameRetries         = 0x59,
  IEEE154_macMinBE                   = 0x4F,
// no identifier defined in standard
  IEEE154_macMinLIFSPeriod           = 0xA0,
// no identifier defined in standard
  IEEE154_macMinSIFSPeriod           = 0xA1,
  IEEE154_macPANId                   = 0x50,
  IEEE154_macPromiscuousMode         = 0x51,
  IEEE154_macResponseWaitTime        = 0x5A,
  IEEE154_macRxOnWhenIdle            = 0x52,
  IEEE154_macSecurityEnabled         = 0x5D,
  IEEE154_macShortAddress            = 0x53,
  IEEE154_macSuperframeOrder         = 0x54,
  IEEE154_macSyncSymbolOffset        = 0x5B,
  IEEE154_macTimestampSupported      = 0x5C,
  IEEE154_macTransactionPersistenceTime = 0x55,

// attributes not present in the standard PIB:
  IEEE154_macPanCoordinator = 0xF0,
};

enum {
  // MAC header indices 
  MHR_INDEX_FC1     = 0,
  MHR_INDEX_FC2     = 1,
  MHR_INDEX_SEQNO   = 2,
  MHR_INDEX_ADDRESS = 3,
  MHR_MAX_LEN       = 23,
  
  // Frame Control field in MHR
  FC1_FRAMETYPE_BEACON       = 0x00,
  FC1_FRAMETYPE_DATA         = 0x01,
  FC1_FRAMETYPE_ACK          = 0x02,
  FC1_FRAMETYPE_CMD          = 0x03,
  FC1_FRAMETYPE_MASK         = 0x07,

  FC1_SECURITY_ENABLED        = 0x08,
  FC1_FRAME_PENDING           = 0x10,
  FC1_ACK_REQUEST             = 0x20,
  FC1_PAN_ID_COMPRESSION      = 0x40,

  FC2_DEST_MODE_SHORT         = 0x08,
  FC2_DEST_MODE_EXTENDED      = 0x0c,
  FC2_DEST_MODE_MASK          = 0x0c,
  FC2_DEST_MODE_OFFSET        = 2,

  FC2_SRC_MODE_SHORT          = 0x80,
  FC2_SRC_MODE_EXTENDED       = 0xc0,
  FC2_SRC_MODE_MASK           = 0xc0,
  FC2_SRC_MODE_OFFSET         = 6,

  FC2_FRAME_VERSION_1         = 0x10,
  FC2_FRAME_VERSION_2         = 0x20,
  FC2_FRAME_VERSION_MASK      = 0x30,
};

#define CAP_TX_CLIENT "CapQueueP.FrameTx.client"
#define INDIRECT_TX_CLIENT "IndirectTx.client"
#define IEEE802154_RADIO_RESOURCE "RadioRxTxP.resource"

enum {
  OUTGOING_SUPERFRAME,
  INCOMING_SUPERFRAME,
};

typedef struct {
  uint8_t length;   // top bit denotes -> promiscuous mode
  uint8_t mhr[MHR_MAX_LEN];  
} ieee154_header_t;

typedef struct {
  uint8_t rssi;
  uint8_t linkQuality;
  uint32_t timestamp;
} ieee154_metadata_t;

typedef struct
{
  uint8_t client;
  uint8_t handle;
  ieee154_header_t *header;
  uint8_t headerLen;
  uint8_t *payload;
  uint8_t payloadLen;
  ieee154_metadata_t *metadata;
} ieee154_txframe_t;

typedef struct
{
  ieee154_header_t header;
  ieee154_metadata_t metadata;
} ieee154_txcontrol_t;

typedef struct {
  ieee154_txframe_t *frame;
  ieee154_macMaxBE_t BE;
  ieee154_macMaxCSMABackoffs_t allowedBackoffs;
  ieee154_macMaxBE_t macMaxBE;
  ieee154_macMinBE_t macMinBE;
  uint8_t NB;
  uint16_t backoff;
  uint16_t backoffElapsed;
  uint32_t transactionTime;
} ieee154_cap_frame_backup_t;

#define MHR(x) (((ieee154_header_t*) (x)->header)->mhr)

// COMMAND frames
enum {
  CMD_FRAME_ASSOCIATION_REQUEST          = 1,
  CMD_FRAME_ASSOCIATION_RESPONSE         = 2,
  CMD_FRAME_DISASSOCIATION_NOTIFICATION  = 3,
  CMD_FRAME_DATA_REQUEST                 = 4,
  CMD_FRAME_PAN_ID_CONFLICT_NOTIFICATION = 5,
  CMD_FRAME_ORPHAN_NOTIFICATION          = 6,
  CMD_FRAME_BEACON_REQUEST               = 7,
  CMD_FRAME_COORDINATOR_REALIGNMENT      = 8,
  CMD_FRAME_GTS_REQUEST                  = 9
};

enum {
  // MAC payload fields inside a beacon frame
  BEACON_INDEX_SF_SPEC1 = 0,
  BEACON_INDEX_SF_SPEC2 = 1,
  BEACON_INDEX_GTS_SPEC = 2,

  SF_SPEC2_PAN_COORD = 0x40,
  SF_SPEC2_ASSOCIATION_PERMIT = 0x80,

  GTS_DESCRIPTOR_COUNT_MASK = 0x07,
  GTS_LENGTH_MASK = 0xF0,
  GTS_LENGTH_OFFSET = 4,
  GTS_SPEC_PERMIT = 0x80,
  
  PENDING_ADDRESS_SHORT_MASK = 0x07,
  PENDING_ADDRESS_EXT_MASK = 0x70,
};

enum {
  // PHY sublayer constants
  IEEE154_aTurnaroundTime              = 12,

  FRAMECTL_LENGTH_MASK                 = 0x7F, // "length" member in ieee154_frame_t
  FRAMECTL_PROMISCUOUS                 = 0x80, // "length" member in ieee154_frame_t
};
#define IEEE154_SUPPORTED_CHANNELPAGE  (IEEE154_SUPPORTED_CHANNELS >> 27)

enum {
  // MAC sublayer constants
  IEEE154_aNumSuperframeSlots          = 16,
  IEEE154_aMaxMPDUUnsecuredOverhead    = 25,
  IEEE154_aMinMPDUOverhead             = 9,
  IEEE154_aBaseSlotDuration            = 60,
  IEEE154_aBaseSuperframeDuration      = (IEEE154_aBaseSlotDuration * IEEE154_aNumSuperframeSlots),
  IEEE154_aGTSDescPersistenceTime      = 4,
  IEEE154_aMaxBeaconOverhead           = 75,
  IEEE154_aMaxBeaconPayloadLength      = (IEEE154_aMaxPHYPacketSize - IEEE154_aMaxBeaconOverhead),
  IEEE154_aMaxLostBeacons              = 4,
  IEEE154_aMaxMACSafePayloadSize       = (IEEE154_aMaxPHYPacketSize -  IEEE154_aMaxMPDUUnsecuredOverhead),
  IEEE154_aMaxMACPayloadSize           = (IEEE154_aMaxPHYPacketSize -  IEEE154_aMinMPDUOverhead),
  IEEE154_aMaxSIFSFrameSize            = 18,
  IEEE154_aMinCAPLength                = 440,
  IEEE154_aUnitBackoffPeriod           = 20,
};


#endif // __TKN154_MAC_H
