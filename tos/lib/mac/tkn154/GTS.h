/*
 * Copyright (c) 2010, CISTER/ISEP - Polytechnic Institute of Porto
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
 * 
 * 
 * 
 * @author Ricardo Severino <rars@isep.ipp.pt>
 * @author Stefano Tennina <sota@isep.ipp.pt>
 * ========================================================================
 */

#ifndef __GTS_H
#define __GTS_H

#define GTS_PERMIT_ENABLED 0x80
#define GTS_MAX_SLOTS 7
#define GTS_TX_DIRECTION 0
#define GTS_RX_DIRECTION 1
#define GTS_ALOC_REQ 1
#define GTS_DEALOC_REQ 0
#define GTS_SEND_BUFFER_SIZE 10

typedef enum gts_op_status
{
  GTS_OP_FAILED =0,
  GTS_OP_SUCCESS = 1,
} gts_op_status_t;

typedef struct
{
  uint8_t gtsCharacteristics;
  uint16_t devAddress;
} gtsDescriptorType;

typedef struct
{
  uint8_t gtsId;
  uint8_t startingSlot;
  uint8_t length;
  uint8_t direction;
  uint16_t devAddress;
  uint8_t expiration;
} gtsInfoEntryType;

//GTS entry (used in the PAN coordinator)
typedef struct
{
  uint8_t gtsId;
  uint8_t startingSlot;
  uint8_t length;
  uint16_t devAddress;
  uint8_t persistenceTime;
} gtsInfoEntryType_null;

typedef struct
{
  uint8_t elementCount;
  uint8_t elementIn;
  uint8_t elementOut;
  uint8_t gtsFrameIndex[GTS_SEND_BUFFER_SIZE];
} gtsSlotElementType;

typedef struct
{
  ieee154_txframe_t *frame[GTS_SEND_BUFFER_SIZE];
  uint8_t availableGtsIndex[GTS_SEND_BUFFER_SIZE];
  uint8_t availableGtsIndexCount;
  uint8_t gtsSendBufferCount;
  uint8_t gtsSendBufferMsgIn;
  uint8_t gtsSendBufferMsgOut;
} gtsBufferType;

#endif
