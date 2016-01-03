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

#ifndef TKNTSCH_PIB_H_
#define TKNTSCH_PIB_H_

#include "plain154_types.h"
#include "tkntsch_types.h"
#include "tkntsch_lock.h"

//#define MAC802154E_DISABLE_CHANNEL_HOPPING 1

enum Plain154e_link_type_e
{
  PLAIN154E_LINK_TYPE_NORMAL = 0, PLAIN154E_LINK_TYPE_ADVERTISING = 1
};

enum Plain154eLinkOptions_e
{
  PLAIN154E_LINK_OPTION_TX = 1,
  PLAIN154E_LINK_OPTION_RX = 2,
  PLAIN154E_LINK_OPTION_SHARED = 4,
  PLAIN154E_LINK_OPTION_TIMEKEEPING = 8
};

enum Plain154eLinkOperations_e
{
  PLAIN154E_ADD_LINK = 0,
  PLAIN154E_DELETE_LINK = 1,
  PLAIN154E_MODIFY_LINK = 2,
};

typedef struct
{
  /* TSCH macSlotframeTable PIB attributes */
  uint8_t macSlotframeHandle;
  uint16_t macSlotframeSize;
} macSlotframeEntry_t;

typedef struct
{
  /* TSCH macLinkTable PIB attributes */
  uint16_t macLinkHandle; // (range: 16 bit)
  uint8_t macLinkOptions; // bitmap (range: 0 - 0x0f)
  uint16_t macLinkType; // enum (range: 16 bit)
  uint8_t sfHandle; // (range: 8 bit)
  // TODO keep the pointer?
  plain154_full_address_t macNodeAddress; // IEEE address NOTE this deviates from the
                                 // standard where it is a short address
  uint16_t macTimeslot; // (range: 16 bit)
  uint16_t macChannelOffset; // (range: 16 bit)
} macLinkEntry_t;

typedef struct
{
  /* TSCH macTimeslotTemplate PIB attributes */
  uint8_t macTimeslotTemplateId; // 0 - 0xf, default: 0
  uint16_t macTsCCAOffset; // default: 1800 us
  uint16_t macTsCCA; // default: 128 us
  uint16_t macTsTxOffset; // default: 2120 us
  uint16_t macTsRxOffset; // default: 1120 us
  uint16_t macTsRxAckDelay; // default: 800 us
  uint16_t macTsTxAckDelay; // default: 1000 us
  uint16_t macTsRxWait; // default: 2200 us
  uint16_t macTsAckWait; // default: 400 us
  uint16_t macTsRxTx; // default: 192 us
  uint16_t macTsMaxAck; // default: 2400 us
  uint16_t macTsMaxTx; // default: 4256 us
  uint16_t macTsTimeslotLength; // default: 10000 us
} macTimeslotTemplate_t;

typedef struct
{ // TODO the PIB needs to be reorganised
  /* general TSCH PIB attributes */
  uint8_t macMinBE; // TSCH-CA default: 1 (range: 0 - maxBE)
  uint8_t macMaxBE; // TSCH-CA default: 7	(range: 3 - 8), 6TSCH default: 3
  uint8_t macMaxFrameRetries; // default: 6
  tkntsch_asn_t macASN;
  uint32_t macBeaconSyncRxTimestamp;

  uint8_t joinPriority;
  uint8_t macASN_MSB;

  bool isCoordinator;

  bool macTSCHcapable;
  bool macTSCHenabled;

  // TODO macSlotframeTable
  macSlotframeEntry_t* activeSlotframe;

  // TODO macLinkTable
  macLinkEntry_t* activeLink;

  macTimeslotTemplate_t* activeTemplate;

  /* general PIB attributes for Hopping Sequence (incomplete) */
  uint8_t macHoppingSequenceID; // (range: 0 - 0xf) default: 0
  uint8_t* macHoppingSequenceList;
  uint16_t macHoppingSequenceLength; // (range: 16 bit)
  uint16_t macCurrentHop;

  // node addresses
  uint16_t macShortAddress;
  plain154_extended_address_t macExtendedAddress;
  plain154_macPANId_t macPanId;

  plain154_macDSN_t macDSN;
  bool macAutoRequest;

  plain154_address_t timeParentAddress;

  /* lock for the pib */
  volatile tkntsch_lock_t lock;
} tkntsch_pib_t;

#define INVALID_BACKOFF (-1)

typedef struct tkntsch_slot_context {
  tkntsch_asn_t macASN;
  uint8_t joinPriority;
  uint32_t t0;
  uint32_t radio_t0;
  macLinkEntry_t* link;
  macTimeslotTemplate_t* tmpl;
  message_t* frame;
  message_t* ack;
  tkntsch_pib_t *macpib;
  uint16_t timeslot;
  uint8_t slottype;
  uint8_t num_transmissions;
  uint8_t macBE;
  int8_t numBackoffSlots;
  int16_t time_correction;
  uint32_t radioDataEndTs;
  uint8_t channel;
  struct {
    bool with_ack:1;
    bool is_coordinator:1;
    bool inactive_slot:1;
    bool internal_error:1;
    bool success:1;
    bool confirm_beacon:1;
    bool confirm_data:1;
    bool indicate_data:1;
    bool indicate_beacon:1;
    bool radio_irq_expected:1;
    bool nack:1;
  } flags;
} tkntsch_slot_context_t;

enum Plain154eErrorCodes_e
{
  PLAIN154E_OK = 0,
  PLAIN154E_STATUS_UNSPECIFIED,
  PLAIN154E_NO_NEXT_ACTIVE_LINK
};


typedef struct
{
  uint8_t totalHIEs;
  uint8_t totalHIEsLength;
  bool correctionIEpresent;
  uint8_t* correctionIEfrom;
} typeHIE_t;

typedef struct
{
  /* Number & Type of IEs present */
  uint8_t totalIEs;   // total no. of useful IEs in the frames
  uint8_t totalIEsLength; // total length occupied by IEs including Termination IE (= 2 octets)
  bool syncIEpresent;
  bool slotframeIEpresent;
  bool timeslotIEpresent;
  bool hoppingIEpresent;
  uint8_t* syncIEfrom;
  uint8_t* slotframeIEfrom;
  uint8_t* timeslotIEfrom;
  uint8_t* hoppingIEfrom;
} typeIE_t;

typedef struct
{
  /* Number & Type of IEs parsed */
  uint8_t noIEparsed;
  bool syncIEparsed;
  bool slotframeIEparsed;
  bool timeslotIEparsed;
  bool hoppingIEparsed;
} typeIEparsed_t;

typedef struct {
  /* To keep track of the slots parsed in Slotframe IE*/
  uint8_t totalSlots;
  uint8_t noSlotsparsed;
  uint8_t noSlotsleft;
  uint8_t* stoppedAt;
} parsedSlots_t;

typedef uint8_t plain154e_state_t;

#endif /* MAC802154E_TSCH_H_ */
