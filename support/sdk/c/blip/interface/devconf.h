/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
#ifndef _CONFIGURE_H_
#define _CONFIGURE_H_

#include <Ieee154.h>

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

nx_struct rf_parms {
    nx_uint16_t short_addr;
    nx_uint16_t lpl_interval;
    nx_uint8_t channel;
};

nx_struct retx_parms {
  nx_uint16_t retries;
  nx_uint16_t delay;
};

typedef nx_struct config_cmd {
  nx_uint8_t cmd;
  nx_struct retx_parms retx;
  nx_struct rf_parms rf;
} config_cmd_t;


typedef nx_struct {
  nx_uint8_t error;
  nx_uint16_t serial_read;
  nx_uint16_t radio_read;
  nx_uint16_t serial_fail;
  nx_uint16_t radio_fail;
  nx_struct retx_parms retx;
  nx_uint8_t ext_addr[8];
  nx_struct rf_parms rf;
} config_reply_t;

#else

enum {
  CONFIGURE_MSG_SIZE = 10,
};
typedef struct config_cmd {
  uint8_t cmd;
  struct {
    uint16_t retries;
    uint16_t delay;
  } retx;
  struct {
    uint16_t short_addr;
    uint16_t lpl_interval;
    uint8_t channel;
  } rf;
} __attribute__((packed)) config_cmd_t;



typedef struct {
  uint8_t error;
  uint16_t serial_read;
  uint16_t radio_read;
  uint16_t serial_fail;
  uint16_t radio_fail;
  struct {
    uint16_t retries;
    uint16_t delay;
  } retx;
  uint8_t  ext_addr[8];
  struct {
    uint16_t short_addr;
    uint16_t lpl_interval;
    uint8_t channel;
  } rf;
} __attribute__((packed)) config_reply_t;

enum {
  TOS_SERIAL_802_15_4_ID = 2,
  TOS_SERIAL_DEVCONF = 3,
};
#endif

#endif

