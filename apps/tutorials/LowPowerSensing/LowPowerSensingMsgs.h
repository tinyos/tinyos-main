/*
 * Copyright (c) 2007 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date July 24, 2007
 */

#ifndef LOWPOWERSENSINGMSGS_H
#define LOWPOWERSENSINGMSGS_H

#include "message.h"
#include "SensorSample.h"

enum {
  AM_SERIAL_REQUEST_SAMPLES_MSG         = 0x92,
  AM_REQUEST_SAMPLES_MSG                = 0x93,

  AM_SAMPLE_MSG                         = 0x98,
  AM_SERIAL_SAMPLE_MSG                  = 0x99,
};

typedef nx_struct serial_request_samples_msg {
  nx_am_addr_t addr;
  nx_uint32_t sample_num;
} serial_request_samples_msg_t;

typedef nx_struct request_samples_msg {
} request_samples_msg_t;

typedef  nx_struct sample_msg {
  nx_sensor_sample_t sample;
} sample_msg_t;

typedef  nx_struct serial_sample_msg {
  nx_am_addr_t  src_addr;
  nx_sensor_sample_t sample;
} serial_sample_msg_t;

#endif //LOWPOWERSENSINGMSGS_H

