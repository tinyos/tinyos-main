/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @version $Revision: 1.19 $ $Date: 2009-09-17 23:36:36 $
 */

#ifndef __Jn516_H__
#define __Jn516_H__

typedef uint8_t jn516_status_t;

#if defined(TFRAMES_ENABLED) && defined(IEEE154FRAMES_ENABLED)
#error "Both TFRAMES and IEEE154FRAMES enabled!"
#endif

/**
 * Jn516 header definition.
 * 
 * An I-frame (interoperability frame) header has an extra network 
 * byte specified by 6LowPAN
 * 
 * Length = length of the header + payload of the packet, minus the size
 *   of the length byte itself (1).  This is what allows for variable 
 *   length packets.
 * 
 * FCF = Frame Control Field, defined in the 802.15.4 specs and the
 *   Jn516 datasheet.
 *
 * DSN = Data Sequence Number, a number incremented for each packet sent
 *   by a particular node.  This is used in acknowledging that packet, 
 *   and also filtering out duplicate packets.
 *
 * DestPan = The destination PAN (personal area network) ID, so your 
 *   network can sit side by side with another TinyOS network and not
 *   interfere.
 * 
 * Dest = The destination address of this packet. 0xFFFF is the broadcast
 *   address.
 *
 * Src = The local node ID that generated the message.
 * 
 * Network = The TinyOS network ID, for interoperability with other types
 *   of 802.15.4 networks. 
 * 
 * Type = TinyOS AM type.  When you create a new AMSenderC(AM_MYMSG), 
 *   the AM_MYMSG definition is the type of packet.
 * 
 * TOSH_DATA_LENGTH defaults to 28, it represents the maximum size of 
 * the payload portion of the packet, and is specified in the 
 * tos/types/message.h file.
 *
 * All of these fields will be filled in automatically by the radio stack 
 * when you attempt to send a message.
 */
/**
 * Jn516 Security Header
 */
typedef nx_struct security_header_t {
  nx_uint8_t secLevel:3;
  nx_uint8_t keyMode:2;
  nx_uint8_t reserved:3;
  nx_uint32_t frameCounter;
  nx_uint8_t keyID[1]; // One byte for now
} security_header_t;







// 1 2 1 2 2 2 1 1 
//typedef nx_struct jn516_header_t {
//  nx_uint8_t length;
//  nx_uint16_t fcf;
//  nx_uint8_t dsn;
//  nx_uint16_t destpan;
//  nx_uint16_t dest;
//  nx_uint16_t src;
//  
//#ifndef TFRAMES_ENABLED
//  /** I-Frame 6LowPAN interoperability byte */
//  nx_uint8_t network;
//#endif

//  nx_uint8_t type;
//} jn516_header_t;






typedef nx_struct jn516_header_t {
  nxle_uint8_t length;
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  nxle_uint16_t destpan;
  nxle_uint16_t dest;
  nxle_uint16_t src;
  /** Jn516 802.15.4 header ends here */
#ifdef Jn516_HW_SECURITY
  security_header_t secHdr;
#endif
  
#ifndef TFRAMES_ENABLED
  /** I-Frame 6LowPAN interoperability byte */
  nxle_uint8_t network;
#endif

  nxle_uint8_t type;
} jn516_header_t;







/**
 * Jn516 Packet Footer
 */
typedef nx_struct jn516_footer_t {
} jn516_footer_t;

/**
 * Jn516 Packet metadata. Contains extra information about the message
 * that will not be transmitted.
 *
 * Note that the first two bytes automatically take in the values of the
 * FCS when the payload is full. Do not modify the first two bytes of metadata.
 */
typedef nx_struct jn516_metadata_t {
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t tx_power;
  nx_bool crc;
  nx_bool ack;
  nx_bool timesync;
  nx_uint32_t timestamp;
  nx_uint16_t rxInterval;

  /** Packet Link Metadata */
#ifdef PACKET_LINK
  nx_uint16_t maxRetries;
  nx_uint16_t retryDelay;
#endif
} jn516_metadata_t;


typedef nx_struct jn516_packet_t {
  jn516_header_t packet;
  nx_uint8_t data[];
} jn516_packet_t;


#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 36
#endif

#ifndef Jn516_DEF_CHANNEL
#define Jn516_DEF_CHANNEL 21
#endif

#ifndef Jn516_DEF_RFPOWER
#define Jn516_DEF_RFPOWER 31
#endif

/**
 * Ideally, your receive history size should be equal to the number of
 * RF neighbors your node will have
 */
#ifndef RECEIVE_HISTORY_SIZE
#define RECEIVE_HISTORY_SIZE 4
#endif

/** 
 * The 6LowPAN NALP ID for a TinyOS network is 63 (TEP 125).
 */
#ifndef TINYOS_6LOWPAN_NETWORK_ID
#define TINYOS_6LOWPAN_NETWORK_ID 0x3f
#endif

//Number of frames that can be held by the queue received by radio in BareP
#ifndef RX_QUEUE_SIZE
#define RX_QUEUE_SIZE 5
#endif

enum {
  // size of the header not including the length byte
  MAC_HEADER_SIZE = sizeof( jn516_header_t ) - 1,
  // size of the footer (FCS field)
  MAC_FOOTER_SIZE = sizeof( uint16_t ),
  // MDU
  MAC_PACKET_SIZE = MAC_HEADER_SIZE + TOSH_DATA_LENGTH + MAC_FOOTER_SIZE,

  JN516_SIZE = MAC_HEADER_SIZE + MAC_FOOTER_SIZE,
};

enum
{
  Jn516_INVALID_TIMESTAMP  = 0x80000000L,
};

#endif
