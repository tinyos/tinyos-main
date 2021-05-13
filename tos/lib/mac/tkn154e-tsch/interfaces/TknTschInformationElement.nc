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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * @author Sonali Deo <deo@tkn.tu-berlin.de>
 */

#include "tkntsch_pib.h"
#include "tkntsch_types.h"

/**
 * Provides Parsing and generation capabilities for these IEs:
 *   5.2.4.11 ACK/NACK time correction IE
 *   5.2.4.13 TSCH synchronization IE
 *   5.2.4.14 TSCH slotframe and link IE
 *   5.2.4.15 TSCH timeslot IE
 *   5.2.4.16 Channel hopping IE
 */
interface TknTschInformationElement
{

  /**
    * Checks what HIE are in the header and marks them in hie
    * Returns TKNTSCH_SUCCESS on successful HIE identification
    */
  command tkntsch_status_t presentHIEs(plain154_header_t* header, typeHIE_t* hie);

  /**
    * Updates the struct type typeIE_t to indicate type & number of IEs present in 'data' section of message_t
    * Reads from the address pointed by param 'data' for the length of 'datalength'
    */
  command tkntsch_status_t presentPIEs(uint8_t* data, uint8_t datalength, typeIE_t* frameIE);

  /**
    * Creates Time Correction Header IE by reading params ack and timecorrection
    * Starts appending the IE in 'data' section of message_t from address given by param 'data'
    * Writes the length of IE in IElen
    * Returns TKNTSCH_SUCCESS on successful creation of IE
    */
  command tkntsch_status_t createTimeCorrection(uint8_t* data, bool ack, int16_t timecorrection, uint8_t* IElen);

  /**
    * Parses Time Correction Header IE by reading from address given by param 'data'
    * Writes values into params ack and timecorrection
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseTimeCorrection(uint8_t* data, bool* ack, int16_t* timecorrection);

  /**
    * Creates Sync IE of type MLME Nested IE by reading params asn and joinpriority
    * Starts appending the IE in 'data' section of message_t from address given by param 'data'
    * Writes the length of IE in IElen
    * Returns TKNTSCH_SUCCESS on successful creation of IE
    */
  command tkntsch_status_t createMlmeSync(uint8_t* data, tkntsch_asn_t* asn, uint8_t joinpriority, uint8_t* IElen);

  /**
    * Parses Sync IE of type MLME Nested IE by reading from address given by param 'data'
    * Writes values into params asn and joinpriority
    * Updates the members of struct type typeIEparsed_t to indicate status & number of IEs parsed
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseMlmeSync(uint8_t* data, tkntsch_asn_t* asn, uint8_t* joinpriority, typeIEparsed_t* parsed);

  /**
    * Creates Slotframe & Link IE of type MLME Nested IE by reading params numSlotframes, slotframes, noLinks and links
    * Starts appending the IE in 'data' section of message_t from address given by param 'data'
    * Writes the length of IE in IElen
    * Returns TKNTSCH_SUCCESS on successful creation of IE
    */
  command tkntsch_status_t createMlmeSlotframe(uint8_t* data, uint8_t numSlotframes, macSlotframeEntry_t* slotframes,
    uint8_t noLinks, macLinkEntry_t* links, uint8_t* IElen);

  /**
    * Parses the complete Slotframe & Link IE of type MLME Nested IE by reading from address given by param 'data'
    * Writes values into params numSlotframes, slotframes, noLinks and links for all slotframes
    * Updates the members of struct type typeIEparsed_t to indicate status & number of IEs parsed
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseMlmeSlotframe(uint8_t* data, uint8_t* numSlotframes, macSlotframeEntry_t* slotframes,
    uint8_t* noLinks, macLinkEntry_t* links, typeIEparsed_t* parsed);

  /**
    * Parses first slotframe of Slotframe & Link IE of type MLME Nested IE by reading from address given by param 'data'
    * Writes values into params numSlotframes, slotframes, noLinks and links for first slotframe only
    * Updates the members of struct type parsedSlots_t to indicate status & number of slotframes parsed
    * Writes the address of location where parsing stops into 'stoppedAt' so that it can be used to resume parsing later
    * Updates the members of struct type typeIEparsed_t to indicate status & number of IEs parsed
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseMlmeFirstSlotframe(uint8_t* data, uint8_t* numSlotframes, macSlotframeEntry_t* slotframes,
    uint8_t* noLinks, macLinkEntry_t* links, parsedSlots_t* numSlotStatus, typeIEparsed_t* parsed);

  /**
    * Parses next slotframe of Slotframe & Link IE of type MLME Nested IE by reading from address given by param 'startAt'
    * Writes values into params slotframes, noLinks and links for one slotframe only
    * Updates the members of struct type parsedSlots_t to indicate status & number of slotframes parsed
    * Writes the address of location where parsing stops into 'stoppedAt' so it can be used to resume parsing later using this function
    * Updates the members of struct type typeIEparsed_t to indicate status & number of IEs parsed
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseMlmeNextSlotframe(uint8_t* startAt, macSlotframeEntry_t* slotframes, uint8_t* noLinks,
    macLinkEntry_t* links, parsedSlots_t* numSlotStatus, typeIEparsed_t* parsed);

  /**
    * Creates Timeslot IE of type MLME Nested IE by reading param template
    * Starts appending the IE in 'data' section of message_t from address given by param 'data'
    * Writes the length of IE in IElen
    * Returns TKNTSCH_SUCCESS on successful creation of IE
    */
  command tkntsch_status_t createMlmeTimeslot(uint8_t* data, macTimeslotTemplate_t* template, uint8_t* IElen);

  /**
    * Parses Timeslot IE of type MLME Nested IE by reading from address given by param 'data'
    * Writes values into param template
    * Updates the members of struct type typeIEparsed_t to indicate status & number of IEs parsed
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseMlmeTimeslot(uint8_t* data, macTimeslotTemplate_t* template, typeIEparsed_t* parsed);

  /**
    * Creates Channel Hopping IE of type MLME Nested IE by reading param sequenceID
    * Starts appending the IE in 'data' section of message_t from address given by param 'data'
    * Writes the length of IE in IElen
    * Returns TKNTSCH_SUCCESS on successful creation of IE
    */
  command tkntsch_status_t createMlmeHoppingSequence(uint8_t* data, uint8_t sequenceID, uint8_t* IElen);

  /**
    * Parses Channel Hopping IE of type MLME Nested IE by reading from address given by param 'data'
    * Writes values into param sequenceID
    * Updates the members of struct type typeIEparsed_t to indicate status & number of IEs parsed
    * Returns TKNTSCH_SUCCESS on successful parsing of IE
    */
  command tkntsch_status_t parseMlmeHoppingSequence(uint8_t* data, uint8_t* sequenceID, typeIEparsed_t* parsed);

}
