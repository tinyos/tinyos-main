 /*
 * Copyright (c) 2010, Vanderbilt University
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * Author: Janos Sallai
 * Author: Thomas Schmid (adapted to CC2520)
 * Author: JeongGil Ko (Security Header Added)
 */

#ifndef __CC2520RADIO_H__
#define __CC2520RADIO_H__

#include <RadioConfig.h>
#include <TinyosNetworkLayer.h>
#include <Ieee154PacketLayer.h>
#include <ActiveMessageLayer.h>
#include <MetadataFlagsLayer.h>
#include <CC2520DriverLayer.h>
#include <TimeStampingLayer.h>
#include <LowPowerListeningLayer.h>
#include <PacketLinkLayer.h>

/**
 * CC2520 Security Header
 */
typedef nx_struct security_header_t {
  nx_uint8_t secLevel:3;
  nx_uint8_t keyMode:2;
  nx_uint8_t reserved:3;
  nx_uint32_t frameCounter;
  nx_uint8_t keyID[1]; // One byte for now
} security_header_t;


typedef nx_struct cc2520packet_header_t
{
  cc2520_header_t cc2520;
  ieee154_simple_header_t ieee154;

#ifdef CC2520_HW_SECURITY
  security_header_t secHdr;
#endif

#ifndef TFRAMES_ENABLED
  network_header_t network;
#endif
#ifndef IEEE154FRAMES_ENABLED
  activemessage_header_t am;
#endif
} cc2520packet_header_t;

typedef nx_struct cc2520packet_footer_t
{
  // the time stamp is not recorded here, time stamped messaged cannot have max length
} cc2520packet_footer_t;

typedef struct cc2520packet_metadata_t
{
#ifdef LOW_POWER_LISTENING
  lpl_metadata_t lpl;
#endif
#ifdef PACKET_LINK
  link_metadata_t link;
#endif
  timestamp_metadata_t timestamp;
  flags_metadata_t flags;
  cc2520_metadata_t cc2520;
} cc2520packet_metadata_t;

enum cc2520_security_enums{
  NO_SEC = 0,
  CBC_MAC_4 = 1,
  CBC_MAC_8 = 2,
  CBC_MAC_16 = 3,
  CTR_MODE = 4,
  CCM_4 = 5,
  CCM_8 = 6,
  CCM_16 = 7
};

#endif//__CC2520RADIO_H__
