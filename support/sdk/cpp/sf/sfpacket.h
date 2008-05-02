/*
 * Copyright (c) 2007, Technische Universitaet Berlin
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
 */
/**
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 */

#ifndef SFPACKET_H
#define SFPACKET_H

// #define DEBUG_SFPACKET

#undef DEBUG
#ifdef DEBUG_SFPACKET
#include <iostream>
#define DEBUG(message) std::cout << message << std::endl;
#else
#define DEBUG(message) 
#endif

#include <iostream>
#include <stdint.h>

#include "serialprotocol.h"
enum {
  SYNC_BYTE = SERIAL_HDLC_FLAG_BYTE,
  ESCAPE_BYTE = SERIAL_HDLC_CTLESC_BYTE,

  SF_ACK = SERIAL_SERIAL_PROTO_ACK,
  SF_PACKET_ACK = SERIAL_SERIAL_PROTO_PACKET_ACK,
  SF_PACKET_NO_ACK = SERIAL_SERIAL_PROTO_PACKET_NOACK,
  SF_UNKNOWN = SERIAL_SERIAL_PROTO_PACKET_UNKNOWN
};

class SFPacket{


public:
    /* max packet length in bytes */
    static const int cMaxPacketLength = 256;

/** member vars **/
protected:
    /* internal buffer */
    char buffer[cMaxPacketLength + 1];
    
    /* length of byte buffer */
    int length;
    /* type */
    int type;
    /* sequence number */
    int seqno;


/** member functions **/
protected:

public:
    SFPacket(int type = SF_PACKET_ACK, int pSeqno = 0);

    ~SFPacket();

    SFPacket(const SFPacket &pPacket);

    /* returns buffer */
    const char* getPayload() const;

    /* returns length of buffer */
    int getLength() const;

    /* return the length that shall be transmitted via TCP */
    int getTcpLength() const;

    /* return the payload of the TCP packet */
    const char* getTcpPayload();
    
    /* returns the seqno of this packet */
    int getSeqno() const;

    /* returns type of packet */
    int getType() const;

    /* sets buffer and length and constructs frame (incl crc) */
    bool setPayload(const char* pBuffer, uint8_t pLength);

    /* sets the seqno */
    void setSeqno(int pSeqno);

    /* sets the type */
    void setType(int pType);

    /* returns max payload length */
    static const int getMaxPayloadLength();

    /* == operator */
    bool operator==(SFPacket const& pPacket);
};

#endif
