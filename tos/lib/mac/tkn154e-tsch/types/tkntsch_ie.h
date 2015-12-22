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
 * @author Sonali Deo <deo@tkn.tu-berlin.de>
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 *
 * ========================================================================
 */

#ifndef _TKNTSCH_IE_H_
#define _TKNTSCH_IE_H_

#define HIE_TIME_CORRECTION_NACK 0x8000
#define HIE_TIME_CORRECTION_MASK 0x0fff

#define PIE_MASK 0x8000
#define PIE_LENGTH_MASK 0x07ff
#define PIE_GROUP_ID_MASK 0x7800
#define PIE_GROUP_ID_SHIFT 11

#define PIE_MLME_GROUP_ID 0x01
#define PIE_MLME_TYPE_MASK 0x8000
#define PIE_MLME_SHORT_LENGTH_MASK 0x00ff
#define PIE_MLME_SHORT_ID_MASK 0x7f00
#define PIE_MLME_SHORT_ID_SHIFT 8
#define PIE_MLME_SHORT_SYNC_ID 0x1a
#define PIE_MLME_SHORT_TS_ID 0x1c
#define PIE_MLME_SHORT_HOPPING_TIMING_ID 0x1d
#define PIE_MLME_SHORT_SF_ID 0x1b
#define PIE_MLME_LONG_LENGTH_MASK 0x07ff
#define PIE_MLME_LONG_ID_MASK 0x7800
#define PIE_MLME_LONG_ID_SHIFT 11
#define PIE_MLME_LONG_HOPPING_ID 0x09

// -----------------------------------------


#define HIE_TERM_NOPIE_LOWER 0x80
#define HIE_TERM_NOPIE_UPPER 0x3f
#define HIE_TERM_PIE_LOWER 0x00
#define HIE_TERM_PIE_UPPER 0x3f
#define HIE_TERM_BYTE_LENGTH 2

#define HIE_TIME_CORRECTION_LOWER 0x02
#define HIE_TIME_CORRECTION_UPPER 0x0f
#define HIE_TIMECORRECTION_BYTE_LENGTH 4

#define PIE_MLME_SYNC_LOWER 6
#define PIE_MLME_SYNC_UPPER 0x1a
#define PIE_MLME_SYNC_BYTE_LENGTH 8

#define PIE_MLME_SF_UPPER 0x1b

#define PIE_MLME_TS_ID_ONLY_LOWER 1
#define PIE_MLME_TS_ID_ONLY_UPPER 0x1c
#define PIE_MLME_TS_ID_ONLY_BYTE_LENGTH 3
#define PIE_MLME_TS_FULL_TEMPLATE_LOWER 25
#define PIE_MLME_TS_FULL_TEMPLATE_UPPER 0x1c
#define PIE_MLME_TS_FULL_TEMPLATE_BYTE_LENGTH 27

#define PIE_MLME_HOPPING_TIMING_LOWER 5
#define PIE_MLME_HOPPING_TIMING_UPPER 0x1d
#define PIE_MLME_HOPPING_TIMING_BYTE_LENGTH 7

#define PIE_MLME_HOPPING_SEQUENCE_IE_LOWER 0x01
#define PIE_MLME_HOPPING_SEQUENCE_IE_UPPER 0xc8
#define PIE_MLME_HOPPING_SEQUENCE_BYTE_LENGTH 3

// -----------------------------------------


//* Copied over from TknTschFramesP.nc: Check which ones should remain here!!! *//
//Using Element ID(8 bits) of Header IEs to define their type
#define TYPE_TIMECORRECTION_IE 0x1e
#define TYPE_LE_CSL_IE 0x1a
#define TYPE_LE_RIT_IE 0x1b
#define TYPE_PAN_DESCRIPTOR_IE 0x1c
#define TYPE_RZ_TIME_IE 0x1d
#define TYPE_GROUP_ACK_IE 0x1f
#define TYPE_LOW_LATENCY_NW_IE 0x20
#define TYPE_LIST_TERMINATION_1 0x7e
#define TYPE_LIST_TERMINATION_2 0x7f

// Masks
#define IE_LEN_MASK 0xfe
#define ELEMENT_ID_MASK 0x01fe





#endif

