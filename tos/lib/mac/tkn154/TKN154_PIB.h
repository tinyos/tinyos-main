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
 * $Date: 2008-06-16 18:00:29 $
 * @author Torsten Halbhuebner <hhuebner.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKN154_PIB_H
#define __TKN154_PIB_H

/**************************************************** 
 * IEEE 802.15.4 PAN information base (PIB)
 */


typedef struct ieee154_PIB_t {

  /**************/
  /* bool types */
  /**************/
   
  // 0x41
  ieee154_macAssociationPermit_t macAssociationPermit;
  // 0x42
  ieee154_macAutoRequest_t macAutoRequest;
  // 0x43
  ieee154_macBattLifeExt_t macBattLifeExt;
  // 0x4D
  ieee154_macGTSPermit_t macGTSPermit;
  // 0x51
  ieee154_macPromiscuousMode_t macPromiscuousMode;
  // 0x52
  ieee154_macRxOnWhenIdle_t macRxOnWhenIdle;
  // 0x56
  ieee154_macAssociatedPANCoord_t macAssociatedPANCoord;
  // 0x5D
  ieee154_macSecurityEnabled_t macSecurityEnabled;
  // no standard attribute
  ieee154_macPanCoordinator_t macPanCoordinator;
  /*****************/
  /* uint8_t types */
  /*****************/

  // 0x00
  ieee154_phyCurrentChannel_t phyCurrentChannel;
  // 0x02
  ieee154_phyTransmitPower_t phyTransmitPower;
  // 0x03
  ieee154_phyCCAMode_t phyCCAMode;
  // 0x04
  ieee154_phyCurrentPage_t phyCurrentPage;
  // 0x44
  ieee154_macBattLifeExtPeriods_t macBattLifeExtPeriods;
  // 0x46
  ieee154_macBeaconPayloadLength_t macBeaconPayloadLength;
  // 0x47
  ieee154_macBeaconOrder_t macBeaconOrder;
  // 0x49
  ieee154_macBSN_t macBSN;
  // 0x4C
  ieee154_macDSN_t macDSN;
  // 0x4E
  ieee154_macMaxCSMABackoffs_t macMaxCSMABackoffs;
  // 0x4F
  ieee154_macMinBE_t macMinBE;
  // 0x54
  ieee154_macSuperframeOrder_t macSuperframeOrder;
  // 0x57
  ieee154_macMaxBE_t macMaxBE;
  // 0x59
  ieee154_macMaxFrameRetries_t macMaxFrameRetries;
  // 0x5a
  ieee154_macResponseWaitTime_t macResponseWaitTime;

  /*****************************/
  /* larger than uint8_t types */
  /*****************************/

  // 0x4B
  ieee154_macCoordShortAddress_t macCoordShortAddress;
  // 0x50
  ieee154_macPANId_t macPANId;
  // 0x53
  ieee154_macShortAddress_t macShortAddress;
  // 0x55
  ieee154_macTransactionPersistenceTime_t macTransactionPersistenceTime;

  // TODO: check type
  ieee154_macMaxFrameTotalWaitTime_t macMaxFrameTotalWaitTime;

  ieee154_macBeaconTxTime_t macBeaconTxTime;
  // 0x4A
  ieee154_macCoordExtendedAddress_t macCoordExtendedAddress;

} ieee154_PIB_t;

// PHY PIB default attributes

#define IEEE154_DEFAULT_CURRENTCHANNEL          26
#define IEEE154_DEFAULT_CHANNELSSUPPORTED_PAGE0 0x07FFF800
#define IEEE154_DEFAULT_CHANNELSSUPPORTED_PAGE1 0
#define IEEE154_DEFAULT_CHANNELSSUPPORTED_PAGE2 0
#define IEEE154_DEFAULT_CCAMODE                 3
#define IEEE154_DEFAULT_CURRENTPAGE             0
#define IEEE154_DEFAULT_TRANSMITPOWER_dBm       0

// MAC PIB default attributes
#define IEEE154_DEFAULT_ASSOCIATEDPANCOORD      FALSE
#define IEEE154_DEFAULT_ASSOCIATIONPERMIT       FALSE
#define IEEE154_DEFAULT_AUTOREQUEST             TRUE
#define IEEE154_DEFAULT_BATTLIFEEXT             FALSE
#define IEEE154_DEFAULT_BATTLIFEEXTPERIODS      6
#define IEEE154_DEFAULT_BEACONPAYLOAD           NULL
#define IEEE154_DEFAULT_BEACONPAYLOADLENGTH     0
#define IEEE154_DEFAULT_BEACONORDER             15
#define IEEE154_DEFAULT_BEACONTXTIME            0
#define IEEE154_DEFAULT_COORDSHORTADDRESS       0xFFFF
#define IEEE154_DEFAULT_GTSPERMIT               TRUE
#define IEEE154_DEFAULT_MAXBE                   5
#define IEEE154_DEFAULT_MAXCSMABACKOFFS         4
#define IEEE154_DEFAULT_MAXFRAMETOTALWAITTIME   2626
#define IEEE154_DEFAULT_MAXFRAMERETRIES         3
#define IEEE154_DEFAULT_MINBE                   3
#define IEEE154_DEFAULT_MINLIFSPERIOD           40
#define IEEE154_DEFAULT_MINSIFSPERIOD           12
#define IEEE154_DEFAULT_PANID                   0xFFFF
#define IEEE154_DEFAULT_PROMISCUOUSMODE         FALSE
#define IEEE154_DEFAULT_RESPONSEWAITTIME        32
#define IEEE154_DEFAULT_RXONWHENIDLE            FALSE
#define IEEE154_DEFAULT_SECURITYENABLED         FALSE
#define IEEE154_DEFAULT_SHORTADDRESS            0xFFFF

#define IEEE154_DEFAULT_SUPERFRAMEORDER         15
#define IEEE154_DEFAULT_SYNCSYMBOLOFFSET        0
#define IEEE154_DEFAULT_TIMESTAMPSUPPORTED      TRUE
#define IEEE154_DEFAULT_TRANSACTIONPERSISTENCETIME  0x01F4

#define IEEE154_INVALID_TIMESTAMP (0xffffffff)

#endif // __TKN154_PIB_H
