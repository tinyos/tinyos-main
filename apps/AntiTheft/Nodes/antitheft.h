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
  AM_ALERTS = 22,
  DIS_SETTINGS = 42,
  COL_ALERTS = 11,

  DEFAULT_ALERT = ALERT_LEDS,
  DEFAULT_DETECT = DETECT_DARK,
  DEFAULT_CHECK_INTERVAL = 1000
};

typedef nx_struct {
  nx_uint8_t alert, detect;
  nx_uint16_t checkInterval;
} settings_t;

typedef nx_struct {
  nx_uint16_t stolenId;
} alert_t;

#endif
