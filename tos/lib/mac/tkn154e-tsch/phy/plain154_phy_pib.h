/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 *
 * ========================================================================
 */

#ifndef _PLAIN154_PHY_PIB_H
#define _PLAIN154_PHY_PIB_H

/**
 * Plain154 PHY PIB attribute identifiers
 */
enum {
  PLAIN154_phyCurrentChannel          = 0x00,
  PLAIN154_phyChannelsSupported       = 0x01,
  PLAIN154_phyTransmitPower           = 0x02,
  PLAIN154_phyCCAMode                 = 0x03,
  PLAIN154_phyCurrentPage             = 0x04,
  PLAIN154_phyMaxFrameDuration        = 0x05,
  PLAIN154_phySHRDuration             = 0x06,
  PLAIN154_phySymbolsPerOctet         = 0x07
};

/**
 * typedefs PIB value types
 */
typedef uint8_t             plain154_phyCurrentChannel_t;
typedef uint32_t            plain154_phyChannelsSupported_t;
typedef uint8_t             plain154_phyTransmitPower_t;
//typedef uint8_t             plain154_phyCCAMode_t;
//typedef uint8_t             plain154_phyCurrentPage_t;
//typedef uint16_t            plain154_phyMaxFrameDuration_t;
//typedef uint8_t             plain154_phySHRDuration_t;
//typedef uint8_t             plain154_phySymbolsPerOctet_t;

/**
 * Plain154 IEEE 802.15.4 PAN PHY information base (PHY PIB)
 */
typedef struct plain154_phy_pib {
  plain154_phyCurrentChannel_t   phyCurrentChannel;
  plain154_phyChannelsSupported_t phyChannelsSupported;
  plain154_phyTransmitPower_t    phyTransmitPower;
//  plain154_phyCCAMode_t          phyCCAMode;
//  plain154_phyCurrentPage_t      phyCurrentPage;
//  plain154_phyMaxFrameDuration_t phyMaxFrameDuration;
//  plain154_phySHRDuration_t      phySHRDuration;
//  plain154_phySymbolsPerOctet_t  phySymbolsPerOctet;
} plain154_phy_pib_t;


#define PLAIN154_SUPPORTED_CHANNELPAGE  (PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE0 >> 27)

/**
 * PHY PIB default attributes
 */
#ifndef PLAIN154_DEFAULT_CURRENTCHANNEL          
  #define PLAIN154_DEFAULT_CURRENTCHANNEL          26
#endif
#ifndef PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE0 
  #define PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE0 0x07FFF800
#endif
#ifndef PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE1 
  #define PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE1 0
#endif
#ifndef PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE2 
  #define PLAIN154_DEFAULT_CHANNELSSUPPORTED_PAGE2 0
#endif
#ifndef PLAIN154_DEFAULT_CCAMODE                 
  #define PLAIN154_DEFAULT_CCAMODE                 3
#endif
#ifndef PLAIN154_DEFAULT_CURRENTPAGE             
  #define PLAIN154_DEFAULT_CURRENTPAGE             0
#endif
#ifndef PLAIN154_DEFAULT_TRANSMITPOWER_dBm       
  #define PLAIN154_DEFAULT_TRANSMITPOWER_dBm       0
#endif



enum { // TODO: this should find a better place to be put 
  PLAIN154_aNumSuperframeSlots          = 16,
  PLAIN154_aBaseSlotDuration            = 60,
  PLAIN154_aBaseSuperframeDuration      = (PLAIN154_aBaseSlotDuration * PLAIN154_aNumSuperframeSlots),
};






#endif