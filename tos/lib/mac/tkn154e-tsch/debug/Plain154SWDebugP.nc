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
 */

#include "TknTschConfigLog.h"
//ifndef TKN_TSCH_LOG_ENABLED_PLAIN154_SWDEBUG
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

#include "plain154_message_structs.h"
#include "plain154_values.h"
#include "message.h"


module Plain154SWDebugP {
  provides {
    interface Plain154SWDebug;
  }
} implementation {
  command void Plain154SWDebug.LOG_DEBUGCF(uint8_t fcf1, uint8_t fcf2) {
    T_LOG_DEBUG("FCF: ");
    // frame version
    switch (fcf2 & PLAIN154_FC2_MASK_VERSION) {
      case PLAIN154_FC2_FRAME_VERSION_1:
        T_LOG_DEBUG("v1");
        break;
      case PLAIN154_FC2_FRAME_VERSION_2:
        T_LOG_DEBUG("v2");
        break;
      default:
        T_LOG_DEBUG("v?");
    }
    switch (fcf1 & PLAIN154_FC1_MASK_FRAMETYPE) {
	    case PLAIN154_FC1_BEACON:
        T_LOG_DEBUG(" BEACON");
        break;
	    case PLAIN154_FC1_DATA:
        T_LOG_DEBUG(" DATA");
        break;
      case PLAIN154_FC1_ACK:
        T_LOG_DEBUG(" ACK");
        break;
      case PLAIN154_FC1_CMD:
        T_LOG_DEBUG(" CMD");
        break;
      default:
        T_LOG_DEBUG(" UNKNOWN");
        break;
    }
    switch ((fcf2 & PLAIN154_FC2_MASK_ADDRMODE_SRC) >> PLAIN154_FC2_BITOFFSET_ADDRMODE_SRC) {
      case PLAIN154_ADDR_NOT_PRESENT:
        T_LOG_DEBUG(" SRC-NONE");
        break;
      case PLAIN154_ADDR_SHORT:
        T_LOG_DEBUG(" SRC-SHORT");
        break;
      case PLAIN154_ADDR_EXTENDED:
        T_LOG_DEBUG(" SRC-LONG");
        break;
      default:
        T_LOG_DEBUG(" SRC-?");
    }
    switch ((fcf2 & PLAIN154_FC2_MASK_ADDRMODE_DEST) >> PLAIN154_FC2_BITOFFSET_ADDRMODE_DEST) {
      case PLAIN154_ADDR_NOT_PRESENT:
        T_LOG_DEBUG(" DEST-NONE");
        break;
      case PLAIN154_ADDR_SHORT:
        T_LOG_DEBUG(" DEST-SHORT");
        break;
      case PLAIN154_ADDR_EXTENDED:
        T_LOG_DEBUG(" DEST-LONG");
        break;
      default:
        T_LOG_DEBUG(" DEST-?");
    }
    if (fcf1 & PLAIN154_FC1_ACK_REQUEST) T_LOG_DEBUG(" ack-req.");
    if (fcf1 & PLAIN154_FC1_PANID_COMPRESSION) T_LOG_DEBUG(" panid-comp.");
    if (fcf1 & PLAIN154_FC1_FRAME_PENDING) T_LOG_DEBUG(" f-pend.");
    if (fcf1 & PLAIN154_FC1_SECURITY) T_LOG_DEBUG(" sec");
    T_LOG_DEBUG("\n");
  }

}
