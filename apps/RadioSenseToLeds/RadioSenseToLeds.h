#ifndef RADIO_SENSE_TO_LEDS_H
#define RADIO_SENSE_TO_LEDS_H

typedef nx_struct radio_sense_msg {
  nx_uint16_t error;
  nx_uint16_t data;
} radio_sense_msg_t;

enum {
  AM_RADIO_SENSE_MSG = 7,
};

#endif
