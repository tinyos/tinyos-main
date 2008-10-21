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
 * $Revision: 1.2 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_H
#define __TKN154_H

/****************************************************
 * IEEE 802.15.4 Enumerations
 */

typedef enum ieee154_status 
{
  IEEE154_SUCCESS                 = 0x00,
  IEEE154_BEACON_LOSS             = 0xE0,
  IEEE154_CHANNEL_ACCESS_FAILURE  = 0xE1,
  IEEE154_COUNTER_ERROR           = 0xDB,
  IEEE154_DENIED                  = 0xE2,
  IEEE154_DISABLE_TRX_FAILURE     = 0xE3,
  IEEE154_FRAME_TOO_LONG          = 0xE5,
  IEEE154_IMPROPER_KEY_TYPE       = 0xDC,
  IEEE154_IMPROPER_SECURITY_LEVEL = 0xDD,
  IEEE154_INVALID_ADDRESS         = 0xF5,
  IEEE154_INVALID_GTS             = 0xE6,
  IEEE154_INVALID_HANDLE          = 0xE7,
  IEEE154_INVALID_INDEX           = 0xF9,
  IEEE154_INVALID_PARAMETER       = 0xE8,
  IEEE154_LIMIT_REACHED           = 0xFA,
  IEEE154_NO_ACK                  = 0xE9,
  IEEE154_NO_BEACON               = 0xEA,
  IEEE154_NO_DATA                 = 0xEB,
  IEEE154_NO_SHORT_ADDRESS        = 0xEC,
  IEEE154_ON_TIME_TOO_LONG        = 0xF6,
  IEEE154_OUT_OF_CAP              = 0xED,
  IEEE154_PAN_ID_CONFLICT         = 0xEE,
  IEEE154_PAST_TIME               = 0xF7,
  IEEE154_READ_ONLY               = 0xFB,
  IEEE154_REALIGNMENT             = 0xEF,
  IEEE154_SCAN_IN_PROGRESS        = 0xFC,
  IEEE154_SECURITY_ERROR          = 0xE4,  //FAILED_SECURITY_CHECK  = 0xE4 //802.15.4_2003
  IEEE154_SUPERFRAME_OVERLAP      = 0xFD,
  IEEE154_TRACKING_OFF            = 0xF8,
  IEEE154_TRANSACTION_EXPIRED     = 0xF0,
  IEEE154_TRANSACTION_OVERFLOW    = 0xF1,
  IEEE154_TX_ACTIVE               = 0xF2,
  IEEE154_UNAVAILABLE_KEY         = 0xF3,
  IEEE154_UNSUPPORTED_ATTRIBUTE   = 0xF4,
  IEEE154_UNSUPPORTED_LEGACY      = 0xDE,
  IEEE154_UNSUPPORTED_SECURITY    = 0xDF,
} ieee154_status_t;

typedef enum ieee154_association_status 
{
  IEEE154_ASSOCIATION_SUCCESSFUL  = 0x00,
  IEEE154_PAN_AT_CAPACITY         = 0x01,   
  IEEE154_ACCESS_DENIED           = 0x02    
} ieee154_association_status_t;

typedef enum ieee154_disassociation_reason 
{
  IEEE154_COORDINATOR_WISHES_DEVICE_TO_LEAVE  = 0x01,   
  IEEE154_DEVICE_WISHES_TO_LEAVE              = 0x02    
} ieee154_disassociation_reason_t;

typedef union ieee154_address {
  // Whether this is a short or extended address
  // depends on the respective addressing mode
  uint16_t shortAddress;
  uint64_t extendedAddress;
} ieee154_address_t;

typedef struct ieee154_security {
  // Whether the first 0, 4 or 8 byte of KeySource
  // are valid depends on the KeyIdMode parameter
  uint8_t SecurityLevel;
  uint8_t KeyIdMode;
  uint8_t KeySource[8];
  uint8_t KeyIndex;
} ieee154_security_t;

typedef nx_struct
{
  nxle_uint8_t AlternatePANCoordinator  :1;
  nxle_uint8_t DeviceType               :1;
  nxle_uint8_t PowerSource              :1;
  nxle_uint8_t ReceiverOnWhenIdle       :1;
  nxle_uint8_t Reserved                 :2;
  nxle_uint8_t SecurityCapability       :1;
  nxle_uint8_t AllocateAddress          :1;
} ieee154_CapabilityInformation_t;

typedef nx_struct
{
  nxle_uint8_t BeaconOrder          :4;
  nxle_uint8_t SuperframeOrder      :4;
  nxle_uint8_t FinalCAPSlot         :4;
  nxle_uint8_t BatteryLifeExtension :1;
  nxle_uint8_t Reserved             :1;
  nxle_uint8_t PANCoordinator       :1;
  nxle_uint8_t AssociationPermit    :1;
} ieee154_SuperframeSpec_t;

typedef struct ieee154_PANDescriptor {
  uint8_t CoordAddrMode;
  uint16_t CoordPANId;
  ieee154_address_t CoordAddress;
  uint8_t LogicalChannel;
  uint8_t ChannelPage;
  ieee154_SuperframeSpec_t SuperframeSpec;
  bool GTSPermit;
  uint8_t LinkQuality;
  uint32_t TimeStamp;
  ieee154_status_t SecurityFailure;
  uint8_t SecurityLevel;
  uint8_t KeyIdMode;
  uint64_t KeySource;
  uint8_t KeyIndex;
} ieee154_PANDescriptor_t;

enum {
  // Values for the PANType parameter of the MLME_RESET.request primitive 
  BEACON_ENABLED_PAN, 
  NONBEACON_ENABLED_PAN,

  // Values for the TxOptions parameter of MCPS_DATA.request()
  TX_OPTIONS_ACK      = 0x01,
  TX_OPTIONS_GTS      = 0x02,
  TX_OPTIONS_INDIRECT = 0x04,

  // Values for Destination/Source Addressing Mode (MCPS_DATA.request(), etc.)
  ADDR_MODE_NOT_PRESENT       = 0x00,
  ADDR_MODE_RESERVED          = 0x01,
  ADDR_MODE_SHORT_ADDRESS     = 0x02,
  ADDR_MODE_EXTENDED_ADDRESS  = 0x03,

  // ScanType parameter for MLME-SCAN primitive
  ENERGY_DETECTION_SCAN    = 0x00,
  ACTIVE_SCAN              = 0x01,
  PASSIVE_SCAN             = 0x02,
  ORPHAN_SCAN              = 0x03,

  // Frame types
  FRAMETYPE_BEACON       = 0x00,
  FRAMETYPE_DATA         = 0x01,
  FRAMETYPE_ACK          = 0x02,
  FRAMETYPE_CMD          = 0x03,
};

/**************************************************** 
 * typedefs PIB value types
 */

typedef uint8_t             ieee154_phyCurrentChannel_t;
typedef uint32_t            ieee154_phyChannelsSupported_t;
typedef uint8_t             ieee154_phyTransmitPower_t;
typedef uint8_t             ieee154_phyCCAMode_t;
typedef uint8_t             ieee154_phyCurrentPage_t;
typedef uint16_t            ieee154_phyMaxFrameDuration_t;
typedef uint8_t             ieee154_phySHRDuration_t;
typedef uint8_t             ieee154_phySymbolsPerOctet_t;

typedef uint8_t             ieee154_macAckWaitDuration_t;
typedef bool                ieee154_macAssociatedPANCoord_t;
typedef bool                ieee154_macAssociationPermit_t;
typedef bool                ieee154_macAutoRequest_t;
typedef bool                ieee154_macBattLifeExt_t;
typedef uint8_t             ieee154_macBattLifeExtPeriods_t;
typedef uint8_t*            ieee154_macBeaconPayload_t;
typedef uint8_t             ieee154_macBeaconPayloadLength_t;
typedef uint8_t             ieee154_macBeaconOrder_t;
typedef uint32_t            ieee154_macBeaconTxTime_t;
typedef uint8_t             ieee154_macBSN_t;
typedef uint64_t            ieee154_macCoordExtendedAddress_t;
typedef uint16_t            ieee154_macCoordShortAddress_t;
typedef uint8_t             ieee154_macDSN_t;
typedef bool                ieee154_macGTSPermit_t;
typedef uint8_t             ieee154_macMaxBE_t;
typedef uint8_t             ieee154_macMaxCSMABackoffs_t;
typedef uint32_t            ieee154_macMaxFrameTotalWaitTime_t;
typedef uint8_t             ieee154_macMaxFrameRetries_t;
typedef uint8_t             ieee154_macMinBE_t;
typedef uint8_t             ieee154_macMinLIFSPeriod_t;
typedef uint8_t             ieee154_macMinSIFSPeriod_t;
typedef uint16_t            ieee154_macPANId_t;
typedef bool                ieee154_macPromiscuousMode_t;
typedef uint8_t             ieee154_macResponseWaitTime_t;
typedef bool                ieee154_macRxOnWhenIdle_t;
typedef bool                ieee154_macSecurityEnabled_t;
typedef uint16_t            ieee154_macShortAddress_t;
typedef uint8_t             ieee154_macSuperframeOrder_t;
typedef uint16_t            ieee154_macSyncSymbolOffset_t;
typedef bool                ieee154_macTimestampSupported_t;
typedef uint16_t            ieee154_macTransactionPersistenceTime_t;

// own typedefs
typedef bool                ieee154_macPanCoordinator_t; 

// When security is implemented the following line should be commented out
#define IEEE154_SECURITY_DISABLED

/**************************************************** 
 * Flags for disabling MAC functionality (to save program memory)
 */

// Disable scanning (MLME_SCAN will not work):
// #define IEEE154_SCAN_DISABLED
//
// Disable beacon tracking (MLME_SYNC will not work):
// #define IEEE154_BEACON_SYNC_DISABLED
//
// Disable beacon transmission (MLME_START will not work):
// #define IEEE154_BEACON_TX_DISABLED
//
// Disable promiscuous mode (PromiscuousMode.start() will not work):
// #define IEEE154_PROMISCUOUS_MODE_DISABLED
//
// Disallow next higher layer to switch to receive mode (MLME_RX_ENABLE will not work):
// #define IEEE154_RXENABLE_DISABLED
//
// Disable association (MLME_ASSOCIATE will not work):
// #define IEEE154_ASSOCIATION_DISABLED
//
// Disable association (MLME_DISASSOCIATE will not work):
// #define IEEE154_DISASSOCIATION_DISABLED
//
// Disable coordinator realignment (MLME_ORPHAN will not work):
// #define IEEE154_COORD_REALIGNMENT_DISABLED
//
// Disable transmission of broadcasts from coordinator to devices:
// #define IEEE154_COORD_BROADCAST_DISABLED

/**************************************************** 
 * Static memory allocation for Queue/Pool
 */

#ifndef TXFRAME_POOL_SIZE
#define TXFRAME_POOL_SIZE 5
#endif

#ifndef TXCONTROL_POOL_SIZE
#define TXCONTROL_POOL_SIZE 5
#endif

#ifndef CAP_TX_QUEUE_SIZE
#define CAP_TX_QUEUE_SIZE 10
#endif

#ifndef INDIRECT_TX_QUEUE_SIZE
#define INDIRECT_TX_QUEUE_SIZE 7
#endif

#ifndef MAX_PENDING_ASSOC_RESPONSES
#define MAX_PENDING_ASSOC_RESPONSES INDIRECT_TX_QUEUE_SIZE
#endif

enum {
  // PHY sublayer constant needed to calculate mpdu size
  IEEE154_aMaxPHYPacketSize          = 127,
};

#endif // __TKN154_H
