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
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 */

#include "tkntsch_types.h"
#include "plain154_types.h"
#include "tkntsch_lock.h"
#include "tkntsch_pib.h"
#include "tkntsch_ie.h"

module TknTschInformationElementP
{
  provides {
    interface TknTschInformationElement as IE;
  }
}
implementation
{

  command tkntsch_status_t IE.presentHIEs(plain154_header_t* header, typeHIE_t* hie) {
    uint8_t hieLength = 0;
    uint8_t* hiePtr = (uint8_t *) header->hie;
    uint16_t ie_header;
    uint8_t ie_length;
    uint8_t ie_eid;

    if ((header == NULL) || (hie == NULL))
      return TKNTSCH_INVALID_PARAMETER;

    hie->totalHIEs = 0;
    hie-> totalHIEsLength = 0;
    hie->correctionIEpresent = FALSE;
    hie->correctionIEfrom = NULL;

    ie_header = hiePtr[0] + (hiePtr[1] << 8);
    ie_length = ie_header & 0x7f;
    ie_eid = (ie_header >> 7) & 0x7f;
    hieLength += 2;
    while (((ie_eid & 0x7e) != 0x7e) && (hieLength < 6)) {
      if (ie_eid == TYPE_TIMECORRECTION_IE) {
        hie->totalHIEs++;
        hie->correctionIEpresent = TRUE;
        hie->correctionIEfrom = (uint8_t *) hiePtr;
      }
      hieLength += ie_length;
      ie_header = hiePtr[0] + (hiePtr[1] << 8);
      ie_length = ie_header & 0x7f;
      ie_eid = (ie_header >> 7) & 0x7f;
      hiePtr = (uint8_t *) (hiePtr + ie_length + 2);
      hieLength += 2;
    }
    hie->totalHIEsLength = hieLength;
    return TKNTSCH_SUCCESS;
  }

  command tkntsch_status_t IE.createTimeCorrection(
      uint8_t* data, bool ack, int16_t timecorrection, uint8_t* IElen
    )
  {
    uint16_t timesync_info;

    if (data == NULL) {
      if (IElen != NULL)
        *IElen = 0;
      return TKNTSCH_INVALID_PARAMETER;
    }

    // make sure the values are in the right range
    if ((timecorrection > 2047) || (timecorrection < -2048)) {
      return TKNTSCH_INVALID_PARAMETER;
    }

    timesync_info = timecorrection & HIE_TIME_CORRECTION_MASK;
    data[0] = HIE_TIME_CORRECTION_LOWER;
    data[1] = HIE_TIME_CORRECTION_UPPER;

    if (ack == FALSE) { // NACK
      timesync_info |= HIE_TIME_CORRECTION_NACK;
    }

    data[2] = timesync_info & 0xff;
    data[3] = (timesync_info >> 8) & 0xff;

    if (IElen != NULL)
      *IElen = HIE_TIMECORRECTION_BYTE_LENGTH;

    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseTimeCorrection(
      uint8_t* data, bool* ack, int16_t* timecorrection)
  {
    uint16_t timesync_info;
    int16_t value;

    if (data == NULL || ack == NULL || timecorrection == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    timesync_info = data[2] + (data[3] << 8);
    *ack = (timesync_info & HIE_TIME_CORRECTION_NACK) ? FALSE : TRUE;

    timesync_info &= ~HIE_TIME_CORRECTION_NACK;

    if (timesync_info & 0x0800) {  // negative
      value = (timesync_info & HIE_TIME_CORRECTION_MASK) + ~HIE_TIME_CORRECTION_MASK;
    } else {  // positive
      value = (timesync_info & HIE_TIME_CORRECTION_MASK);
   }

    if ((value > 2047) || (value < -2048)) {
      return TKNTSCH_INVALID_PARAMETER;
    }

    *timecorrection = value;

    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.createMlmeSync(
      uint8_t* data, tkntsch_asn_t* asn, uint8_t joinpriority, uint8_t* IElen)
  {
    if (data == NULL || asn == NULL || IElen == NULL) {
      *IElen = 0;
      return TKNTSCH_INVALID_PARAMETER;
    }
    data[0] = PIE_MLME_SYNC_LOWER;
    data[1] = PIE_MLME_SYNC_UPPER;

    // MLME IE content - Sync IE
    data[2] = TKNTSCH_ASN_GET_LSBBYTE_1(*asn);
    data[3] = TKNTSCH_ASN_GET_LSBBYTE_2(*asn);
    data[4] = TKNTSCH_ASN_GET_LSBBYTE_3(*asn);
    data[5] = TKNTSCH_ASN_GET_LSBBYTE_4(*asn);
    data[6] = TKNTSCH_ASN_GET_LSBBYTE_5(*asn);
    data[7] = joinpriority;

    *IElen = PIE_MLME_SYNC_BYTE_LENGTH;
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseMlmeSync(
      uint8_t* data, tkntsch_asn_t* asn, uint8_t* joinpriority, typeIEparsed_t* parsed
    )
  {
    if (data == NULL || asn == NULL || joinpriority == NULL)
      return TKNTSCH_INVALID_PARAMETER;
    *asn = 0;
    /*
    TKNTSCH_ASN_SET_LSBBYTE_1(asn, data[2]);
    TKNTSCH_ASN_SET_LSBBYTE_2(asn, data[3]);
    TKNTSCH_ASN_SET_LSBBYTE_3(asn, data[4]);
    TKNTSCH_ASN_SET_LSBBYTE_4(asn, data[5]);
    TKNTSCH_ASN_SET_LSBBYTE_5(asn, data[6]);*/

    *asn = data[2];
    *asn |= data[3]<<8;
    *asn |= data[4]<<16;
    *asn |= data[5]<<24;
    *asn |= ((uint64_t)data[6]) << 32;

    *joinpriority = data[7];
    if (parsed != NULL) {
      parsed->syncIEparsed = TRUE;
      parsed->noIEparsed += 1;
    }
    return TKNTSCH_SUCCESS;
  }


  // TODO: Having a for loop without checking for maximum length is very dangerous! Introduce a maxDataLength field here!
  command tkntsch_status_t IE.createMlmeSlotframe(
      uint8_t* data, uint8_t numSlotframes, macSlotframeEntry_t* slotframes,
      uint8_t numLinks, macLinkEntry_t* links, uint8_t* IElen)
  {
    int data_offset;
    int sf_index;
    uint8_t sfHandle;
    int numLinksOffset;
    int numSfLinks;
    int link_index;

    if (data == NULL || slotframes == NULL || links == NULL || IElen == NULL) {
      *IElen = 0;
      return TKNTSCH_INVALID_PARAMETER;
    }
    data_offset = 0;

    data[data_offset++] = 0;  // is set on exit
    data[data_offset++] = PIE_MLME_SF_UPPER;

    //MLME IE content
    data[data_offset++] = numSlotframes;

    //for number of slotframes
    for (sf_index = 0; sf_index < numSlotframes; sf_index++) {
      sfHandle = slotframes[sf_index].macSlotframeHandle;
      data[data_offset++] = sfHandle;
      data[data_offset++] = (slotframes[sf_index].macSlotframeSize) & 0xff;
      data[data_offset++] = (slotframes[sf_index].macSlotframeSize >> 8) & 0xff;
      numLinksOffset = data_offset++;  // will be set when the num is known

      numSfLinks = 0;
      //for number of links inside slotframes
      for (link_index = 0; link_index < numLinks; link_index++) {
        if (links[link_index].sfHandle != sfHandle)
          continue;
        data[data_offset++] = (links[link_index].macTimeslot) & 0xff;
        data[data_offset++] = (links[link_index].macTimeslot >> 8) & 0xff;
        data[data_offset++] = (links[link_index].macChannelOffset) & 0xff;
        data[data_offset++] = (links[link_index].macChannelOffset >> 8) & 0xff;
        data[data_offset++] = links[link_index].macLinkOptions;
        numSfLinks++;
      }
      // number of links
      data[numLinksOffset] = numSfLinks;
    }

    data[0] = (data_offset - 2) & 0xff;

    *IElen = data_offset;
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseMlmeSlotframe(
      uint8_t* data, uint8_t* numSlotframes, macSlotframeEntry_t* slotframes,
      uint8_t* numLinks, macLinkEntry_t* links, typeIEparsed_t* parsed
    )
  { /* To parse and store all slotframes at once */
    uint8_t max_numLinks;
    uint8_t abs_max_links;
    int data_offset;
    int sf_index;
    uint8_t sfHandle;
    int numLinksOffset;
    int numSfLinks;
    int link_index;

    if (data == NULL || numSlotframes == NULL || slotframes == NULL
        || numLinks == NULL || links == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    //MLME IE content
    if (data[2] > *numSlotframes)
      return TKNTSCH_MAX_SLOTFRAMES_EXCEEDED;

    *numSlotframes = data[2];
    abs_max_links = *numLinks;
    *numLinks = 0;
    data_offset = 3;

    //for number of slotframes
    for (sf_index = 0; sf_index < *numSlotframes; sf_index++) {
      sfHandle = data[data_offset++];
      slotframes[sf_index].macSlotframeHandle = sfHandle;
      slotframes[sf_index].macSlotframeSize = (data[data_offset++] | ((data[data_offset++] & 0xff) << 8)) & 0xffff;

      numLinksOffset = data_offset;
      data_offset++;
      max_numLinks = data[numLinksOffset];
      numSfLinks = 0;

      if ((*numLinks + max_numLinks) > abs_max_links)
        return TKNTSCH_MAX_LINKS_EXCEEDED;

      //for number of links inside each slotframe
      for (link_index = 0; link_index < max_numLinks; link_index++) {
        numSfLinks++;

        links[link_index].macTimeslot = (data[data_offset++] | ((data[data_offset++] & 0xff) << 8)) & 0xffff;
        links[link_index].macChannelOffset = (data[data_offset++] | ((data[data_offset++] & 0xff) << 8)) & 0xffff;
        links[link_index].macLinkOptions = data[data_offset++];
      }

      // number of links actually parsed
      *numLinks += (uint8_t) numSfLinks;
    }
    if (parsed != NULL) {
      parsed->slotframeIEparsed = TRUE;
      parsed->noIEparsed += 1;
    }
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseMlmeFirstSlotframe(
      uint8_t* data, uint8_t* numSlotframes, macSlotframeEntry_t* slotframes,
      uint8_t* numLinks, macLinkEntry_t* links, parsedSlots_t* noSlotStatus,
      typeIEparsed_t* parsed
    )
  {
    /* -To parse first slotframe or frame with only one slotframe
       -Should be used first when parsing frame with multiple slotframes */

    uint8_t max_numLinks;
    int numSfLinks;
    int data_offset;
    int link_index;
    uint8_t slots_parsed = 0;

    if (data == NULL || numSlotframes == NULL || slotframes == NULL || numLinks == NULL || links == NULL || noSlotStatus == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    //MLME IE content
    *numSlotframes = data[2];
    noSlotStatus->totalSlots = *numSlotframes;

    //for first slotframe
    slotframes->macSlotframeHandle = data[3];
    slotframes->macSlotframeSize = (data[4] | ((data[5] & 0xff) << 8)) & 0xffff;
    max_numLinks = data[6];
    data_offset = 7;
    numSfLinks = 0;

    //for number of links inside each slotframe
    for (link_index = 0; link_index < max_numLinks; link_index++) {
      numSfLinks++;

      links[link_index].macTimeslot = (data[data_offset++] | ((data[data_offset++] & 0xff) << 8)) & 0xffff;
      links[link_index].macChannelOffset = (data[data_offset++] | ((data[data_offset++] & 0xff) << 8)) & 0xffff;
      links[link_index].macLinkOptions = data[data_offset++];
    }

    // number of links actually parsed
    *numLinks = (uint8_t) numSfLinks;

    // number of slots parsed
    slots_parsed += 1;
    noSlotStatus->noSlotsparsed = slots_parsed;
    noSlotStatus->noSlotsleft = *numSlotframes-slots_parsed;

    if(noSlotStatus->noSlotsleft == 0) {
      if (parsed != NULL) {
        parsed->slotframeIEparsed = TRUE;
        parsed->noIEparsed += 1;
      }
    }

    noSlotStatus->stoppedAt = &data[data_offset];
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseMlmeNextSlotframe(
      uint8_t* startAt, macSlotframeEntry_t* slotframes, uint8_t* numLinks,
      macLinkEntry_t* links, parsedSlots_t* noSlotStatus, typeIEparsed_t* parsed
    )
  {
    uint8_t max_numLinks;
    int numSfLinks;
    int data_offset;
    uint8_t slots_parsed;
    int link_index;

    if (startAt == NULL || slotframes == NULL || numLinks == NULL
        || links == NULL || noSlotStatus == NULL || parsed == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    noSlotStatus->noSlotsparsed += 1;
    slots_parsed = noSlotStatus->noSlotsparsed;

    if (slots_parsed > noSlotStatus->totalSlots)
      return TKNTSCH_INVALID_PARAMETER;

    slotframes->macSlotframeHandle = startAt[0];
    slotframes->macSlotframeSize = (startAt[1] | ((startAt[2] & 0xff) << 8)) & 0xffff;
    max_numLinks = startAt[3];
    data_offset = 4;
    numSfLinks = 0;

    // for number of links inside each slotframe
    for (link_index = 0; link_index < max_numLinks; link_index++) {
      numSfLinks++;
      links[link_index].macTimeslot = (startAt[data_offset++] | ((startAt[data_offset++] & 0xff) << 8)) & 0xffff;
      links[link_index].macChannelOffset = (startAt[data_offset++] | ((startAt[data_offset++] & 0xff) << 8)) & 0xffff;
      links[link_index].macLinkOptions = startAt[data_offset++];
    }

    // number of links actually parsed
    *numLinks = (uint8_t) numSfLinks;
    noSlotStatus->noSlotsleft -= 1;

    if(noSlotStatus->noSlotsleft == 0) {
      parsed->slotframeIEparsed = TRUE;
      parsed->noIEparsed += 1;
    }

    noSlotStatus->stoppedAt = &startAt[data_offset];
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.createMlmeTimeslot(
      uint8_t* data, macTimeslotTemplate_t* template, uint8_t* IElen
    )
  {
    if (data == NULL || template == NULL || IElen == NULL) {
      *IElen = 0;
      return TKNTSCH_INVALID_PARAMETER;
    }

  if((template->macTsCCAOffset & 0xff) == 0)  {
    data[0] = PIE_MLME_TS_ID_ONLY_LOWER;
    data[1] = PIE_MLME_TS_ID_ONLY_UPPER;
    data[2] = template->macTimeslotTemplateId;
    *IElen  = PIE_MLME_TS_ID_ONLY_BYTE_LENGTH;
  }
  else {
    data[0]  =  PIE_MLME_TS_FULL_TEMPLATE_LOWER;
    data[1]  =  PIE_MLME_TS_FULL_TEMPLATE_UPPER;
    data[2]  =  template->macTimeslotTemplateId;
    data[3]  =  template->macTsCCAOffset            & 0xff;
    data[4]  = (template->macTsCCAOffset >> 8)      & 0xff;
    data[5]  =  template->macTsCCA                  & 0xff;
    data[6]  = (template->macTsCCA >> 8)            & 0xff;
    data[7]  =  template->macTsTxOffset             & 0xff;
    data[8]  = (template->macTsTxOffset >> 8)       & 0xff;
    data[9]  =  template->macTsRxOffset             & 0xff;
    data[10] = (template->macTsRxOffset >> 8)       & 0xff;
    data[11] =  template->macTsRxAckDelay           & 0xff;
    data[12] = (template->macTsRxAckDelay >> 8)     & 0xff;
    data[13] =  template->macTsTxAckDelay           & 0xff;
    data[14] = (template->macTsTxAckDelay >> 8)     & 0xff;
    data[15] =  template->macTsRxWait               & 0xff;
    data[16] = (template->macTsRxWait >> 8)         & 0xff;
    data[17] =  template->macTsAckWait              & 0xff;
    data[18] = (template->macTsAckWait >> 8)        & 0xff;
    data[19] =  template->macTsRxTx                 & 0xff;
    data[20] = (template->macTsRxTx >> 8)           & 0xff;
    data[21] =  template->macTsMaxAck               & 0xff;
    data[22] = (template->macTsMaxAck >> 8)         & 0xff;
    data[23] =  template->macTsMaxTx                & 0xff;
    data[24] = (template->macTsMaxTx >> 8)          & 0xff;
    data[25] =  template->macTsTimeslotLength       & 0xff;
    data[26] = (template->macTsTimeslotLength >> 8) & 0xff;
    *IElen = PIE_MLME_TS_FULL_TEMPLATE_BYTE_LENGTH;
  }
  return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseMlmeTimeslot(
      uint8_t* data, macTimeslotTemplate_t* template, typeIEparsed_t* parsed
    )
  {
    if (data == NULL || template == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    if(data[0] == PIE_MLME_TS_ID_ONLY_LOWER) {
      template->macTimeslotTemplateId = data[2];
    } else if (data[0] == PIE_MLME_TS_FULL_TEMPLATE_LOWER) {
      template->macTimeslotTemplateId = data[2];
      template->macTsCCAOffset        = data[3]  | (data[4]  << 8);
      template->macTsCCA              = data[5]  | (data[6]  << 8);
      template->macTsTxOffset         = data[7]  | (data[8]  << 8);
      template->macTsRxOffset         = data[9]  | (data[10] << 8);
      template->macTsRxAckDelay       = data[11] | (data[12] << 8);
      template->macTsTxAckDelay       = data[13] | (data[14] << 8);
      template->macTsRxWait           = data[15] | (data[16] << 8);
      template->macTsAckWait          = data[17] | (data[18] << 8);
      template->macTsRxTx             = data[19] | (data[20] << 8);
      template->macTsMaxAck           = data[21] | (data[22] << 8);
      template->macTsMaxTx            = data[23] | (data[24] << 8);
      template->macTsTimeslotLength   = data[25] | (data[26] << 8);
    }
    else {
      return TKNTSCH_PARSING_FAILED;
    }
    if (parsed != NULL) {
      parsed->timeslotIEparsed = TRUE;
      parsed->noIEparsed += 1;
    }
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.createMlmeHoppingSequence(
      uint8_t* data, uint8_t sequenceID, uint8_t* IElen
    )
  {
    // verify parameters
    if (data == NULL || IElen == NULL) {
      *IElen = 0;
      return TKNTSCH_INVALID_PARAMETER;
    }

    data[0] = PIE_MLME_HOPPING_SEQUENCE_IE_LOWER;
    data[1] = PIE_MLME_HOPPING_SEQUENCE_IE_UPPER;
    data[2] = sequenceID;

    *IElen = PIE_MLME_HOPPING_SEQUENCE_BYTE_LENGTH;
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.parseMlmeHoppingSequence(
      uint8_t* data, uint8_t* sequenceID, typeIEparsed_t* parsed
    )
  {
    if (data == NULL || sequenceID == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    *sequenceID = data[2];
    if (parsed != NULL) {
      parsed->hoppingIEparsed = TRUE;
      parsed->noIEparsed += 1;
    }
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t IE.presentPIEs(uint8_t* data, uint8_t datalength, typeIE_t* frameIE)
  {
    //uint8_t typeIE;
    uint8_t numIE = 0;
    //uint8_t arrayIndex = 0;
    uint16_t ieHeader;
    //uint8_t pie_bytes_remain = 0;

    frameIE->syncIEpresent = FALSE;
    frameIE->timeslotIEpresent = FALSE;
    frameIE->hoppingIEpresent = FALSE;
    frameIE->slotframeIEpresent = FALSE;
    frameIE->syncIEfrom = NULL;

    ieHeader = data[0] + (data[1] << 8);

    // check if IE belongs to payload (validity check)
    if (ieHeader & PIE_MASK) {
      uint8_t groupLength, groupID, processedBytes;
      groupLength = ieHeader & PIE_LENGTH_MASK;
      groupID = (ieHeader & PIE_GROUP_ID_MASK) >> PIE_GROUP_ID_SHIFT;
      processedBytes = 0;

      /* At the current state only MLME (nested) PIE are supported */
      if ((groupID == PIE_MLME_GROUP_ID) && (processedBytes <= datalength)){
        processedBytes += 2;  // MLME (nested) header (outer)
        while (processedBytes <= datalength) {
          uint8_t subID, subLength;
          ieHeader = data[processedBytes] + (data[processedBytes + 1] << 8);
          if (ieHeader & PIE_MLME_TYPE_MASK) {  // long MLME
            subLength = ieHeader & PIE_MLME_LONG_LENGTH_MASK;
            subID = (ieHeader & PIE_MLME_LONG_ID_MASK) >> PIE_MLME_LONG_ID_SHIFT;
          } else {  // short MLME (nested)
            subLength = ieHeader & PIE_MLME_SHORT_LENGTH_MASK;
            subID = (ieHeader & PIE_MLME_SHORT_ID_MASK) >> PIE_MLME_SHORT_ID_SHIFT;
          }

          switch(subID) {
            case PIE_MLME_SHORT_SYNC_ID:
              frameIE->syncIEpresent = TRUE;
              frameIE->syncIEfrom = &data[processedBytes];
              numIE++;
              break;

            case PIE_MLME_SHORT_TS_ID:
              frameIE->timeslotIEpresent = TRUE;
              frameIE->timeslotIEfrom = &data[processedBytes];
              numIE++;
              break;

            case PIE_MLME_LONG_HOPPING_ID:
              frameIE->hoppingIEpresent = TRUE;
              frameIE->hoppingIEfrom = &data[processedBytes];
              numIE++;
              break;

            case PIE_MLME_SHORT_SF_ID:
              frameIE->slotframeIEpresent = TRUE;
              frameIE->slotframeIEfrom = &data[processedBytes];
              numIE++;
              break;

            default:
              return TKNTSCH_FAIL;
          }
          processedBytes += subLength;
          processedBytes += 2; // header bytes are not included in length
          if (numIE > 4) {
            return TKNTSCH_FAIL;
          }
          if ((processedBytes == (groupLength + 2)) && (processedBytes <= datalength)) {
            frameIE->totalIEs = numIE;
            frameIE->totalIEsLength = processedBytes;
            return TKNTSCH_SUCCESS;
          }
        }
      } else {
        return TKNTSCH_FAIL;
      }
    } else {
      return TKNTSCH_FAIL;
    }

    // TODO is this the right way to catch unhandled corner cases?
    return TKNTSCH_FAIL;
  }
}
