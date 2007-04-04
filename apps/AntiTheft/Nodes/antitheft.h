// $Id: antitheft.h,v 1.3 2007-04-04 22:06:22 idgay Exp $
/*
 * Copyright (c) 2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 *
 * @author David Gay
 */
#ifndef ANTITHEFT_H
#define ANTITHEFT_H

enum {
  ALERT_LEDS = 1,
  ALERT_SOUND = 2,
  ALERT_RADIO = 4,
  ALERT_ROOT = 8,

  DETECT_DARK = 1,
  DETECT_ACCEL = 2,

  AM_SETTINGS = 54,
  AM_THEFT = 99,
  AM_ALERT = 22,
  DIS_SETTINGS = 42,
  COL_ALERTS = 11,

  DEFAULT_ALERT = ALERT_LEDS,
  DEFAULT_DETECT = DETECT_DARK,
  DEFAULT_CHECK_INTERVAL = 1000
};

typedef nx_struct settings {
  nx_uint8_t alert, detect;
  nx_uint16_t checkInterval;
} settings_t;

typedef nx_struct alert {
  nx_uint16_t stolenId;
} alert_t;

#endif
