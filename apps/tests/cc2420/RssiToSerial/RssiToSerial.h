
/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
 /**
  * @author Jared Hill
  */
  
#ifndef RSSI_TO_SERIAL_H
#define RSSI_TO_SERIAL_H

typedef nx_struct rssi_serial_msg {
  nx_uint16_t rssiAvgValue;
  nx_uint16_t rssiLargestValue;
  nx_uint8_t channel;
} rssi_serial_msg_t;

enum {
  AM_RSSI_SERIAL_MSG = 134,
  WAIT_TIME = 256,
  //* Using log2 samples to avoid a divide. Sending a packet every 1 second will allow
  //* allow about 5000 samples. A packet every half second allows for 2500 samples, and
  //* a packet every quarter second allows for 1250 samples. 
    
  // When to send a packet is based upon how many samples have been taken, not a 
  // predetermined amount of time. Rough estimates of time can be found using the 
  // conversion stated above. 
  LOG2SAMPLES = 7,
};



#endif
