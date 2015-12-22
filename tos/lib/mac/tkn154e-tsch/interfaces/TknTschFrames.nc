/**
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
 * @author Sonali Deo <deo@tkn.tu-berlin.de>
 */

#include <message.h>
#include "tkntsch_types.h"

/**
 * Provides Parsing and creation capabilities for these frames:
 * Enhanced Frames in compliance with IEEE Std 802.15.4e-2012
 *   5.2.2.1 Beacon frame format
 *   5.2.2.2 Data frame format
 *   5.2.2.3 Acknowledgment frame format
 *
 * Short Frames in compliance with IEEE Std 802.15.4-2006
 *   7.2.2.1 Beacon frame format
 *   7.2.2.2 Data frame format
 *   7.2.2.3 Acknowledgment frame format
 */

interface TknTschFrames
{
  /**
    * Creates Acknowledgement frame in compliance with IEEE Std 802.15.4-2006
    * Uses params 'msg' & 'msglength' to write into header section of message_t
    * Returns TKNTSCH_SUCCESS on successful creation of frame
    */
  command tkntsch_status_t createAckFrame(message_t* msg, uint8_t msglength);

  /**
    * Creates Enhanced Acknowledgement frame in compliance with IEEE Std 802.15.4e-2012
    * Returns TKNTSCH_SUCCESS on successful creation of enhanced frame
    */
  command tkntsch_status_t createEnhancedAckFrame(message_t* msg, uint8_t dstAddrMode, plain154_address_t* dstAddr, uint16_t dstPanID, int16_t timeCorrection, bool ack);

  /**
    * Creates Enhanced Beacon frame in compliance with IEEE Std 802.15.4e-2012
    * Uses params 'msg', 'msglength' to write into header section of message_t
    * Appends Sync, Timeslot, Slotframe & Channel Hopping IEs in data section of message_t
    * Appends 'payload' into data section of message_t upto 'payloadlength' after IE
    * Returns TKNTSCH_SUCCESS on successful creation of enhanced frame
    */
  command tkntsch_status_t createEnhancedBeaconFrame(message_t* msg, plain154_txframe_t *txFrame, uint8_t *payloadLen, bool hasSyncIE, bool hasTsIE, bool hasHoppingIE, bool hasSfIE);

  /**
    * Creates Data frame in compliance with IEEE Std 802.15.4-2006
    * Uses params 'msg', 'msglength' to write into header section of message_t
    * Writes 'payload' into data section of message_t upto 'payloadlength'
    * Returns TKNTSCH_SUCCESS on successful creation of frame
    */
  command tkntsch_status_t createDataFrame(message_t* msg, uint8_t* payload, uint8_t payloadlength);

  /**
    * Parses Time Correction IE from Enhanced Acknowledgement frame
    * Ignores unknown IEs, if present in the frame
    * Writes the address from where payload starts and its length into 'payload' and 'payloadlength'
    * Returns TKNTSCH_SUCCESS on successful parsing of frame
    */
  command tkntsch_status_t parseEnhancedAckFrame(message_t* msg, uint8_t* payload, uint8_t* payloadlength);

  /**
    * Parses the Enhanced Beacon frame to determine which IEs are present in it
    * Doesn't count unknown IEs, if present in the frame
    * Writes the address from where payload starts and its length into 'payload' and 'payloadlength'
    * Returns TKNTSCH_SUCCESS on successful parsing of frame
    */
  command tkntsch_status_t parseEnhancedBeaconFrame(message_t* msg, uint8_t* payload, uint8_t* payloadlength);
}
