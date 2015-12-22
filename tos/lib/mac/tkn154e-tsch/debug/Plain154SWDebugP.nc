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

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

#include "plain154_message_structs.h"
#include "plain154_values.h"
#include "message.h"


module Plain154SWDebugP {
  provides {
    interface Plain154SWDebug;
  }
} implementation {
  command void Plain154SWDebug.printFCF(uint8_t fcf1, uint8_t fcf2) {
    printf("FCF: ");
    // frame version
    switch (fcf2 & PLAIN154_FC2_MASK_VERSION) {
      case PLAIN154_FC2_FRAME_VERSION_1:
        printf("v1");
        break;
      case PLAIN154_FC2_FRAME_VERSION_2:
        printf("v2");
        break;
      default:
        printf("v?");
    }
    switch (fcf1 & PLAIN154_FC1_MASK_FRAMETYPE) {
	  case PLAIN154_FC1_BEACON:
        printf(" BEACON");
        break;
	  case PLAIN154_FC1_DATA:
        printf(" DATA");
        break;
	  case PLAIN154_FC1_ACK:
        printf(" ACK");
        break;
	  case PLAIN154_FC1_CMD:
        printf(" CMD");
        break;
	  default:
        printf(" UNKNOWN");
        break;
    }
    switch ((fcf2 & PLAIN154_FC2_MASK_ADDRMODE_SRC) >> PLAIN154_FC2_BITOFFSET_ADDRMODE_SRC) {
	  case PLAIN154_ADDR_NOT_PRESENT:
        printf(" SRC-NONE");
        break;
	  case PLAIN154_ADDR_SHORT:
        printf(" SRC-SHORT");
        break;
	  case PLAIN154_ADDR_EXTENDED:
        printf(" SRC-LONG");
        break;
	  default:
        printf(" SRC-?");
    }
    switch ((fcf2 & PLAIN154_FC2_MASK_ADDRMODE_DEST) >> PLAIN154_FC2_BITOFFSET_ADDRMODE_DEST) {
	  case PLAIN154_ADDR_NOT_PRESENT:
        printf(" DEST-NONE");
        break;
	  case PLAIN154_ADDR_SHORT:
        printf(" DEST-SHORT");
        break;
	  case PLAIN154_ADDR_EXTENDED:
        printf(" DEST-LONG");
        break;
	  default:
        printf(" DEST-?");
    }
    if (fcf1 & PLAIN154_FC1_ACK_REQUEST) printf(" ack-req.");
    if (fcf1 & PLAIN154_FC1_PANID_COMPRESSION) printf(" panid-comp.");
    if (fcf1 & PLAIN154_FC1_FRAME_PENDING) printf(" f-pend.");
    if (fcf1 & PLAIN154_FC1_SECURITY) printf(" sec");
    printf("\n");
  }

}
