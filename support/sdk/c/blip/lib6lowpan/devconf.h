/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#ifndef _CONFIGURE_H_
#define _CONFIGURE_H_

#include "6lowpan.h"

enum {
  CONFIG_ECHO = 0,       // ping the device for status information
  CONFIG_SET_PARM = 1,   // instruct the device to set its hardware addr
  CONFIG_REBOOT = 2,
  CONFIG_KEEPALIVE = 3,
};

enum {
  CONFIG_ERROR_OK,
  CONFIG_ERROR_FAIL,
  CONFIG_ERROR_BOOTED,
};

enum {
  KEEPALIVE_INTERVAL = 500000,
  KEEPALIVE_TIMEOUT = 5000,
};
                                  
#ifndef PC


typedef nx_struct config_cmd {
  nx_uint8_t cmd;
  nx_struct {
    nx_uint16_t retries;
    nx_uint16_t delay;
  } retx;
  nx_struct {
    nx_uint16_t addr;
    nx_uint8_t channel;
  } rf;
} config_cmd_t;


typedef nx_struct {
  nx_uint8_t error;
  nx_uint16_t addr;
  nx_uint16_t serial_read;
  nx_uint16_t radio_read;
  nx_uint16_t serial_fail;
  nx_uint16_t radio_fail;
} config_reply_t; 

#else

enum {
  CONFIGURE_MSG_SIZE = 8,
};
typedef struct config_cmd {
  uint8_t cmd;
  struct {
    uint16_t retries;
    uint16_t delay;
  } retx;
  struct {
    ieee154_saddr_t addr;
    uint8_t channel;
  } rf;
} __attribute__((packed)) config_cmd_t;



typedef struct {
  uint8_t error;
  ieee154_saddr_t addr;
  uint16_t serial_read;
  uint16_t radio_read;
  uint16_t serial_fail;
  uint16_t radio_fail;
} __attribute__((packed)) config_reply_t;

enum {
  TOS_SERIAL_802_15_4_ID = 2,
  TOS_SERIAL_DEVCONF = 3,
};

#endif

#endif

