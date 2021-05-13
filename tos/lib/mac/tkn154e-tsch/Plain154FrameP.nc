/*
 * Copyright (c) 2014, Technische Universitaet Berlin
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
 * Based on lib/mac/tkn154/PibP.nc by Jan Hauer.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * This component maintains access to the header of IEEE 15.4 frames.
 */

/* TODO: 1. getIEList() & setIEList() - bit 9 of FCF
*/


#include "plain154_types.h"
#include "plain154_message_structs.h"
#include "message.h"
#include "plain154_values.h"

#define GET_HEADER(x) ((plain154_header_t*) ((void*) (x)->header))

#define GET_VERSION(pheader)          (uint8_t)(((pheader)->fcf2 & PLAIN154_FC2_MASK_VERSION) >> PLAIN154_FC2_BITOFFSET_VERSION)
#define SET_VERSION(pheader, version) (pheader)->fcf2 |= (version) << PLAIN154_FC2_BITOFFSET_VERSION;
#define GET_FRAMETYPE(pheader)        (uint8_t)(((pheader)->fcf1 & PLAIN154_FC1_MASK_FRAMETYPE) >> PLAIN154_FC1_BITOFFSET_FRAMETYPE)
#define SET_FRAMETYPE(pheader, type)  (pheader)->fcf1 |= (type) << PLAIN154_FC1_BITOFFSET_FRAMETYPE;
#define GET_ADDR_MODE_SRC(pheader)    (uint8_t)(((pheader)->fcf2 & PLAIN154_FC2_MASK_ADDRMODE_SRC) >> PLAIN154_FC2_BITOFFSET_ADDRMODE_SRC)
#define GET_ADDR_MODE_DEST(pheader)   (uint8_t)(((pheader)->fcf2 & PLAIN154_FC2_MASK_ADDRMODE_DEST) >> PLAIN154_FC2_BITOFFSET_ADDRMODE_DEST)

module Plain154FrameP {
  provides
  {
    interface Plain154Frame as Frame;
  }
}
implementation
{
  async command error_t Frame.setAddressingFields(plain154_header_t* header,
      uint8_t srcAddrMode,
      uint8_t dstAddrMode,
      uint16_t srcPANID,
      uint16_t dstPANID,
      plain154_address_t *srcAddr,
      plain154_address_t *dstAddr,
      uint8_t frameVersion,
      bool compressPanId)
  {
    bool srcPresent, destPresent;

    // FCF
    header->fcf2 &= ~ (uint8_t)(PLAIN154_FC2_MASK_ADDRMODE_DEST | PLAIN154_FC2_MASK_ADDRMODE_SRC | PLAIN154_FC2_MASK_VERSION);
    header->fcf2 |= ((dstAddrMode << PLAIN154_FC2_BITOFFSET_ADDRMODE_DEST) & PLAIN154_FC2_MASK_ADDRMODE_DEST);
    header->fcf2 |= ((srcAddrMode << PLAIN154_FC2_BITOFFSET_ADDRMODE_SRC) & PLAIN154_FC2_MASK_ADDRMODE_SRC);
    header->fcf2 |= (uint8_t) ((frameVersion << PLAIN154_FC2_BITOFFSET_VERSION) & PLAIN154_FC2_MASK_VERSION);

    // PAN IDs and compression flag
    srcPresent = (bool) (srcAddrMode >= PLAIN154_ADDR_SIMPLE);
    destPresent = (bool) (dstAddrMode >= PLAIN154_ADDR_SIMPLE);
    switch (frameVersion) {
      case PLAIN154_FRAMEVERSION_0:
      case PLAIN154_FRAMEVERSION_1:
        if (destPresent && srcPresent && (dstPANID == srcPANID))
          header->fcf1 |= PLAIN154_FC1_PANID_COMPRESSION;
        else
          header->fcf1 &= ~((uint8_t)PLAIN154_FC1_PANID_COMPRESSION);
        break;
      case PLAIN154_FRAMEVERSION_2:
        if (compressPanId) {
          header->fcf1 |= PLAIN154_FC1_PANID_COMPRESSION;
        }
        else {
          header->fcf1 &= ~((uint8_t)PLAIN154_FC1_PANID_COMPRESSION);
        }
        break;
      default:
        return EINVAL;
    }

    // PAN ID set (with regard to compression)
    switch (frameVersion) {
      case PLAIN154_FRAMEVERSION_0:
      case PLAIN154_FRAMEVERSION_1:
        if (dstAddrMode >= PLAIN154_ADDR_SIMPLE)
          header->destpan = dstPANID;
        if ((srcAddrMode >= PLAIN154_ADDR_SIMPLE) && (compressPanId == FALSE)) {
            header->srcpan = srcPANID;
        }
        break;
      case PLAIN154_FRAMEVERSION_2:
        if (destPresent) {
          if (compressPanId == FALSE)
            header->destpan = (nxle_uint16_t) dstPANID;  // case 3 & 4 (line 9 & 12 in table 2a)
        } else {  // dstAddrMode == 0
          if (srcPresent) {
            if (compressPanId == FALSE)
              header->srcpan = (nxle_uint16_t) srcPANID;  // case 2 (line 5 in table 2a)
          } else {  // srcAddrMode == 0
            if (compressPanId == TRUE)
              header->destpan = (nxle_uint16_t) dstPANID;  // case 1 (line 3 in table 2a)
          }
        }
        break;
      default:
        return EINVAL;
      }

    // Dest. addr.
    if (destPresent) {
      if (dstAddr == NULL)
        return EINVAL;
      switch (dstAddrMode) {
        //case PLAIN154_ADDR_SIMPLE:
        // TODO implement simple addr
        case PLAIN154_ADDR_SHORT:
          header->dest.short_addr = (nxle_uint16_t) dstAddr->shortAddress;
          break;
        case PLAIN154_ADDR_EXTENDED:
          header->dest.long_addr = (nxle_uint64_t) dstAddr->extendedAddress;
          break;
        default:
          return EINVAL;
      }
    }

    // Src. addr.
    if (srcPresent) {
      if (srcAddr == NULL)
        return EINVAL;
      switch (srcAddrMode) {
        case PLAIN154_ADDR_SIMPLE:
          // TODO implement simple addr
        case PLAIN154_ADDR_SHORT:
          header->src.short_addr = (nxle_uint16_t) srcAddr->shortAddress;
          break;
        case PLAIN154_ADDR_EXTENDED:
          header->src.long_addr = (nxle_uint64_t) srcAddr->extendedAddress;
          break;
        default:
          return EINVAL;
      }
    }

    return SUCCESS;
  }

  async command uint8_t Frame.getFrameType(plain154_header_t* header)
  {
    return GET_FRAMETYPE(header);
  }

  async command void Frame.setFrameType(plain154_header_t* header, uint8_t type)
  {
    SET_FRAMETYPE(header, type);
  }

  async command plain154_header_t* Frame.getHeader(message_t* frame)
  {
    plain154_header_t *h = GET_HEADER(frame);
    return h;
  }

  async command error_t Frame.getActualHeaderLength(plain154_header_t* header, uint8_t *length)
  {
    uint8_t len = 0;
    uint8_t version = GET_VERSION(header);
    uint16_t tmp16;

    // FCF
    len += 2;

    // SPAN
    if (call Frame.getSrcPANId(header, &tmp16) == SUCCESS) {
      len += 2;
    }

    // DPAN
    if (call Frame.getDstPANId(header, &tmp16) == SUCCESS) {
      len += 2;
    }

    // SADDR
    switch (GET_ADDR_MODE_SRC(header)) {
      case PLAIN154_ADDR_NOT_PRESENT:
        break;
      case PLAIN154_ADDR_SIMPLE:
        len += 1;
        break;
      case PLAIN154_ADDR_SHORT:
        len += 2;
        break;
      case PLAIN154_ADDR_EXTENDED:
        len += 8;
        break;
      default:
        // TODO log the error
        return FAIL;
    }

    // DADDR
    switch (GET_ADDR_MODE_DEST(header)) {
      case PLAIN154_ADDR_NOT_PRESENT:
        break;
      case PLAIN154_ADDR_SIMPLE:
        len += 1;
        break;
      case PLAIN154_ADDR_SHORT:
        len += 2;
        break;
      case PLAIN154_ADDR_EXTENDED:
        len += 8;
        break;
      default:
        // TODO log the error
        return FAIL;
    }

    switch (version) {
      case PLAIN154_FRAMEVERSION_0:
      case PLAIN154_FRAMEVERSION_1:
        // DSN
        len += 1;
        break;
      case PLAIN154_FRAMEVERSION_2:
        // DSN
        if ((header->fcf2 & PLAIN154_FC2_SEQNO_SUPPRESSION) == 0)
            len += 1;
        break;
      default:
        return FAIL;
    }

    if (call Frame.isIEListPresent(header)) {
      uint8_t hieLength = 0;
      uint8_t* hiePtr = (uint8_t *) header->hie;
      uint16_t ie_header;
      uint8_t ie_length;
      uint8_t ie_eid;
      ie_header = hiePtr[0] + (hiePtr[1] << 8);
      ie_length = ie_header & 0x7f;
      ie_eid = (ie_header >> 7) & 0x7f;
      hieLength += 2;
      while (((ie_eid & 0x7e) != 0x7e) && (hieLength < 6)) {
        // Check for HIE termination (EID bits 7-14; value 0x7e or 0x7f means termination)
        // lowest bit (7th in first byte) is not checked, since the same for 0x7e and 0x7f
        hieLength += ie_length;
        ie_header = hiePtr[0] + (hiePtr[1] << 8);
        ie_length = ie_header & 0x7f;
        ie_eid = (ie_header >> 7) & 0x7f;
        hieLength += 2;
      }
      len += hieLength;
    }

    // NOTE no need to handle security or IE header

//    len = sizeof(plain154_header_t);
    *length = len;
    return SUCCESS;
  }

  async command uint8_t Frame.getDSN(plain154_header_t* header)
  {
    return header->dsn;
  }

  async command void Frame.setDSN(plain154_header_t* header, uint8_t dsn)
  {
    header->dsn = dsn;
  }

  async command uint8_t Frame.getFrameVersion(plain154_header_t* header)
  {
    return GET_VERSION(header);
  }

  async command void Frame.setFrameVersion(plain154_header_t* header, uint8_t version)
  {
    SET_VERSION(header, version);
  }

  async command bool Frame.isAckRequested(plain154_header_t* header)
  {
    if (header->fcf1 & PLAIN154_FC1_ACK_REQUEST)
      return TRUE;
    else
      return FALSE;
  }

  async command void Frame.setAckRequest(plain154_header_t* header, bool ack_req)
  {
    if (ack_req)
      header->fcf1 |= PLAIN154_FC1_ACK_REQUEST;
    else
      header->fcf1 &= ~((uint8_t)PLAIN154_FC1_ACK_REQUEST);
  }

  async command uint8_t Frame.getSrcAddrMode(plain154_header_t* header)
  {
    return GET_ADDR_MODE_SRC(header);
  }

  async command error_t Frame.getSrcAddr(plain154_header_t* header, plain154_address_t *address)
  {
    uint8_t srcMode = GET_ADDR_MODE_SRC(header);

    if (srcMode == PLAIN154_ADDR_NOT_PRESENT)
      return FAIL;

    if (srcMode == PLAIN154_ADDR_SHORT)
      address->shortAddress = (nxle_uint16_t) header->src.short_addr;
    else if (srcMode == PLAIN154_ADDR_SIMPLE)
      return FAIL; // TODO implement simple 8bit addresses
    else {
//      call FrameUtility.convertToNative(&address->extendedAddress, (&h->src.long_addr));
      address->extendedAddress = (nxle_uint64_t) header->src.long_addr;
    }
    return SUCCESS;
  }

  async command error_t Frame.getSrcPANId(plain154_header_t* header, uint16_t *PANID)
  {
    uint8_t destAddrPresent = GET_ADDR_MODE_DEST(header) >= PLAIN154_ADDR_SIMPLE;
    uint8_t srcAddrPresent = GET_ADDR_MODE_SRC(header) >= PLAIN154_ADDR_SIMPLE;
    bool panIDCompression = (bool) (header->fcf1 & PLAIN154_FC1_PANID_COMPRESSION);

    // see 802.15.4e p.61 Table 2a
    if (!srcAddrPresent)
      return FAIL;
    switch (GET_VERSION(header)) {
      case PLAIN154_FRAMEVERSION_0:
      case PLAIN154_FRAMEVERSION_1:
        if (header->fcf1 & PLAIN154_FC1_PANID_COMPRESSION) {
          if (!destAddrPresent)
            return FAIL;
          else
            *PANID = (nxle_uint16_t) header->destpan;
        }
        else
          *PANID = (nxle_uint16_t) header->srcpan;
        break;
      case PLAIN154_FRAMEVERSION_2:
        if (srcAddrPresent) {
          if (!destAddrPresent) {
            if (!panIDCompression) {
              *PANID = (nxle_uint16_t) header->srcpan;  // case 2 (line 5 in table 2a)
            } else return FAIL;
          } else return FAIL;
        } else return FAIL;
        break;
      default:
        return FAIL;
    }

    return SUCCESS;
  }

  async command error_t Frame.getHeaderHints(plain154_header_t* header, plain154_header_hints_t *hints)
  {
    uint8_t destAddrPresent = GET_ADDR_MODE_DEST(header) >= PLAIN154_ADDR_SIMPLE;
    uint8_t srcAddrPresent = GET_ADDR_MODE_SRC(header) >= PLAIN154_ADDR_SIMPLE;
    bool panIDCompression = (bool) (header->fcf1 & PLAIN154_FC1_PANID_COMPRESSION);

    if (hints == NULL) return FAIL;

    // dsn
    if ((header->fcf2 & PLAIN154_FC2_SEQNO_SUPPRESSION) == 0)
      hints->hasDsn = TRUE;
    else
      hints->hasDsn = FALSE;

    // src pan
    if (!srcAddrPresent)
      hints->hasSrcPanId = FALSE;
    else {
      switch (GET_VERSION(header)) {
        case PLAIN154_FRAMEVERSION_0:
        case PLAIN154_FRAMEVERSION_1:
          if (panIDCompression) {
            hints->hasSrcPanId = FALSE;
          }
          else {
            hints->hasSrcPanId = TRUE;
          }
          break;
        case PLAIN154_FRAMEVERSION_2:
          if (!destAddrPresent) {
            if (!panIDCompression) {
              hints->hasSrcPanId = TRUE;
            } else {
              hints->hasSrcPanId = FALSE;
            }
          } else {
            hints->hasSrcPanId = FALSE;
          }
          break;
        default:
          return FAIL;
      }
    }

    // dst pan
    switch (GET_VERSION(header)) {
      case PLAIN154_FRAMEVERSION_0:
      case PLAIN154_FRAMEVERSION_1:
        if (!destAddrPresent) {
          hints->hasDstPanId = FALSE;
        }
        else {
          hints->hasDstPanId = TRUE;
        }
        break;
      case PLAIN154_FRAMEVERSION_2:
        if (destAddrPresent) {
          if (!panIDCompression) {
            hints->hasDstPanId = TRUE;
          } else {
            hints->hasDstPanId = FALSE;
          }
        } else /* (!destAddrPresent) */ {
          if (srcAddrPresent) {
            hints->hasDstPanId = FALSE;
          } else /* (!srcAddrPresent) */ {
            if (panIDCompression) {
              hints->hasDstPanId = TRUE;
            } else {
              hints->hasDstPanId = FALSE;
            }
          }
        }
        break;
      default:
        return FAIL;
    }

    // src addr
    hints->hasSrcAddr = srcAddrPresent;

    // dst addr
    hints->hasDstAddr = destAddrPresent;

    return SUCCESS;
  }

  async command uint8_t Frame.getDstAddrMode(plain154_header_t* header)
  {
    return GET_ADDR_MODE_DEST(header);
  }

  async command error_t Frame.getDstAddr(plain154_header_t* header, plain154_address_t *address)
  {
    uint8_t destMode = GET_ADDR_MODE_DEST(header);

    if (destMode == PLAIN154_ADDR_NOT_PRESENT)
      return FAIL;

    if (destMode == PLAIN154_ADDR_SHORT)
      address->shortAddress = (nxle_uint16_t) header->dest.short_addr;
    else if (destMode == PLAIN154_ADDR_SIMPLE)
      return FAIL; // TODO implement simple 8bit addresses
    else {
      //call FrameUtility.convertToNative(&address->extendedAddress, (&header->dest.long_addr));
      address->extendedAddress = (nxle_uint64_t) header->dest.long_addr;
    }

    return SUCCESS;
  }

  async command error_t Frame.getDstPANId(plain154_header_t* header, uint16_t *PANID)
  {
    bool destAddrPresent = (bool) (GET_ADDR_MODE_DEST(header) >= PLAIN154_ADDR_SIMPLE);
    bool srcAddrPresent = (bool) (GET_ADDR_MODE_SRC(header) >= PLAIN154_ADDR_SIMPLE);
    bool panIDCompression = (bool) (header->fcf1 & PLAIN154_FC1_PANID_COMPRESSION);

    // see 802.15.4e p.61 Table 2a
    switch (GET_VERSION(header)) {
      case PLAIN154_FRAMEVERSION_0:
      case PLAIN154_FRAMEVERSION_1:
        if (!destAddrPresent)
          return FAIL;
        *PANID = (nxle_uint16_t) header->destpan;
        break;
      case PLAIN154_FRAMEVERSION_2:
        if (destAddrPresent) {
          if (!panIDCompression) {
            *PANID = (nxle_uint16_t) header->destpan;  // case 3 & 4 (line 9 & 12 in table 2a)
          } else return FAIL;
        } else /* (!destAddrPresent) */ {
          if (srcAddrPresent) {
            return FAIL;
          } else /* (!srcAddrPresent) */ {
            if (panIDCompression) {
              *PANID = (nxle_uint16_t) header->destpan;  // case 1 (line 3 in table 2a)
            } else return FAIL;
          }
        }
        break;
      default:
        return FAIL;
    }
    return SUCCESS;
  }

  async command bool Frame.hasPanidCompression(plain154_header_t* header)
  {
    if (header->fcf1 & PLAIN154_FC1_PANID_COMPRESSION)
        return TRUE;
    else
        return FALSE;
  }

  async command bool Frame.isFramePending(plain154_header_t* header)
  {
    if (header->fcf1 & PLAIN154_FC1_FRAME_PENDING)
        return TRUE;
    else
        return FALSE;
  }

  async command void Frame.setFramePending(plain154_header_t* header, bool pending)
  {
    if (pending)
      header->fcf1 |= PLAIN154_FC1_FRAME_PENDING;
    else
      header->fcf1 &= ~((uint8_t)PLAIN154_FC1_FRAME_PENDING);
  }

  async command bool Frame.isIEListPresent(plain154_header_t* header)
  {
    if (header->fcf2 & PLAIN154_FC2_IE_LIST_PRESENT)
        return TRUE;
    else
        return FALSE;
  }

  async command void Frame.setIEListPresent(plain154_header_t* header, bool IEList)
  {
    if (IEList)
      header->fcf2 |= PLAIN154_FC2_IE_LIST_PRESENT;
    else
      header->fcf2 &= ~((uint8_t)PLAIN154_FC2_IE_LIST_PRESENT);
  }
}
