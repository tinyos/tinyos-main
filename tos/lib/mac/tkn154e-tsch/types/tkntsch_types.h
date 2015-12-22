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
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __TKNTSCH_TYPES_H
#define __TKNTSCH_TYPES_H

#include "plain154_types.h"
#include "plain154_values.h"

// -------------------

// This enum contains new types for status in IEEE 802.15.4e-TSCH
enum tkntsch_status_e {
  TKNTSCH_SUCCESS = 0,
  TKNTSCH_NO_SYNC = 1,
  TKNTSCH_INVALID_PARAMETER,
  TKNTSCH_SLOTFRAME_NOT_FOUND,
  TKNTSCH_MAX_SLOTFRAMES_EXCEEDED,
  TKNTSCH_UNSUPPORTED_FEATURE,
  TKNTSCH_UNKNOWN_LINK,
  TKNTSCH_MAX_LINKS_EXCEEDED,
  TKNTSCH_BUSY,
  TKNTSCH_TRANSACTION_OVERFLOW,
  TKNTSCH_INTERNAL_ERROR,
  TKNTSCH_NOT_IMPLEMENTED_YET,
  TKNTSCH_MALFORMED_FRAME,
  TKNTSCH_FAIL,
  TKNTSCH_PARSING_FAILED
};
typedef uint8_t tkntsch_status_t;

// -------------------

typedef uint64_t tkntsch_asn_t;
#define TKNTSCH_ASN_GET_LSBBYTE_1(asn) (((asn)) & 0xff)
#define TKNTSCH_ASN_GET_LSBBYTE_2(asn) (((asn) >> 8) & 0xff)
#define TKNTSCH_ASN_GET_LSBBYTE_3(asn) (((asn) >> 16) & 0xff)
#define TKNTSCH_ASN_GET_LSBBYTE_4(asn) (((asn) >> 24) & 0xff)
#define TKNTSCH_ASN_GET_LSBBYTE_5(asn) (((asn) >> 32) & 0xff)

// The following caused endian reverse on Jennic
#define TKNTSCH_ASN_SET_LSBBYTE_1(asn, value) ( ( ((uint8_t *) asn)[0]) = value)
#define TKNTSCH_ASN_SET_LSBBYTE_2(asn, value) ( ( ((uint8_t *) asn)[1]) = value)
#define TKNTSCH_ASN_SET_LSBBYTE_3(asn, value) ( ( ((uint8_t *) asn)[2]) = value)
#define TKNTSCH_ASN_SET_LSBBYTE_4(asn, value) ( ( ((uint8_t *) asn)[3]) = value)
#define TKNTSCH_ASN_SET_LSBBYTE_5(asn, value) ( ( ((uint8_t *) asn)[4]) = value)

/*
#define TKNTSCH_ASN_SET_LSBBYTE_1(asn, value) (*asn = *asn + (uint8_t)value)
#define TKNTSCH_ASN_SET_LSBBYTE_2(asn, value) (*asn = *asn + ((uint8_t)value)<<8)
#define TKNTSCH_ASN_SET_LSBBYTE_3(asn, value) (*asn = *asn + ((uint8_t)value)<<16)
#define TKNTSCH_ASN_SET_LSBBYTE_4(asn, value) (*asn = *asn + ((uint8_t)value)<<24)
#define TKNTSCH_ASN_SET_LSBBYTE_5(asn, value) (*asn = *asn + ((uint8_t)value)<<32)
*/
// TODO implement ASN macros: increment, compare, ...

// -------------------

enum tkntsch_slotframe_operation_e {
  TKNTSCH_ADD_SLOTFRAME = 0,
  TKNTSCH_DELETE_SLOTFRAME = 1,
  TKNTSCH_MODIFY_SLOTFRAME = 2
};
typedef uint8_t tkntsch_slotframe_operation_t;

// -------------------

enum tkntsch_link_operation_e {
  TKNTSCH_LINK_OPERATION_ADD = 0,
  TKNTSCH_LINK_OPERATION_DELETE = 1,
  TKNTSCH_LINK_OPERATION_MODIFY = 2
};
typedef uint8_t tkntsch_link_operation_t;

enum tkntsch_link_type_e {
  TKNTSCH_LINK_TYPE_NORMAL = 0,
  TKNTSCH_LINK_TYPE_ADVERTISING = 1
};
typedef uint8_t tkntsch_link_type_t;

// -------------------

enum tkntsch_mode_e {
  TKNTSCH_MODE_ON = 0,
  TKNTSCH_MODE_OFF = 1
};
typedef uint8_t tkntsch_mode_t;

// -------------------

enum tkntsch_beacon_type_e {
  TKNTSCH_BEACON_TYPE_BEACON = 0,
  TKNTSCH_BEACON_TYPE_ENHANCED_BEACON = 1
};
typedef uint8_t tkntsch_beacon_type_t;

// -------------------

//lengths of all IE's


// -------------------
// -------------------


typedef struct tsch_hopping_descriptor {
  uint8_t HoppingSequenceID;
  uint16_t HoppingSequenceLength;
  uint16_t* HoppingSequence;
  uint16_t ChannelOffset;
  uint16_t ChannelOffsetBitmapLength;
  uint8_t* ChannelOffsetBitmap;
} tkntsch_hopping_descriptor_t;



/* *************************************************/
// The following types are copied from
// tos/lib/mac/tkn143/TKN154.h written by Jan Hauer

// Once they are changed/adapted, they should be named
// according to TknTsch naming and removed
// from this section.

typedef enum plain154_association_status
{
  PLAIN154_ASSOCIATION_SUCCESSFUL  = 0x00,
  PLAIN154_PAN_AT_CAPACITY         = 0x01,
  PLAIN154_ACCESS_DENIED           = 0x02
} plain154_association_status_t;

typedef enum plain154_disassociation_reason
{
  PLAIN154_COORDINATOR_WISHES_DEVICE_TO_LEAVE  = 0x01,
  PLAIN154_DEVICE_WISHES_TO_LEAVE              = 0x02
} plain154_disassociation_reason_t;
typedef struct plain154_security {
  // Whether the first 0, 4 or 8 byte of KeySource
  // are valid depends on the KeyIdMode parameter
  uint8_t SecurityLevel;
  uint8_t KeyIdMode;
  uint8_t KeySource[8];
  uint8_t KeyIndex;
} plain154_security_t;

typedef nx_struct
{
  nxle_uint8_t AlternatePANCoordinator  :1;
  nxle_uint8_t DeviceType               :1;
  nxle_uint8_t PowerSource              :1;
  nxle_uint8_t ReceiverOnWhenIdle       :1;
  nxle_uint8_t Reserved                 :2;
  nxle_uint8_t SecurityCapability       :1;
  nxle_uint8_t AllocateAddress          :1;
} plain154_CapabilityInformation_t;

// TODO probably not needed
typedef struct plain154_PANDescriptor {
  uint8_t CoordAddrMode;
  bool CoordPANIdPresent;
  uint16_t CoordPANId;
  plain154_address_t CoordAddress;
//  uint8_t LogicalChannel;
  uint8_t ChannelPage;
//  plain154_SuperframeSpec_t SuperframeSpec;
  bool GTSPermit;
  uint8_t LinkQuality;
  uint32_t TimeStamp;
  plain154_status_t SecurityFailure;
  uint8_t SecurityLevel;
  uint8_t KeyIdMode;
  uint64_t KeySource;
  uint8_t KeyIndex;
  uint64_t ASN;
} plain154_PANDescriptor_t;

/* *************************************************/



#endif // __TKN154E_H
