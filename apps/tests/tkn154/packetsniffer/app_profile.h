/*
 * Copyright (c) 2009, Technische Universitaet Berlin
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2009/06/10 09:23:45 $
 * @author: Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */

#ifndef __APP_PROFILE_H
#define __APP_PROFILE_H

enum {
  INITAL_RADIO_CHANNEL = 26, // may be changed later via command over serial line
  RX_QUEUE_SIZE = 10,        // max. packets queued after received over radio
};

typedef nx_struct sniffer_metadata 
{
  nxle_uint8_t lqi;        // LQI (see CC2420 datasheet for definition)
  nxle_int8_t rssi;        // RSSI in dBm
  nxle_uint8_t crc;        // 0: CRC check failed, 1: CRC check passed
  nxle_uint8_t mhrLen;     // length of the MAC header (for convenience)
  nxle_uint8_t channel;    // 802.15.4 channel on which the frame was received (11..26)  
  nxle_uint32_t timestamp; // elapsed time since booting in symbols (1 tick = 16 us)
} sniffer_metadata_t;

#endif
