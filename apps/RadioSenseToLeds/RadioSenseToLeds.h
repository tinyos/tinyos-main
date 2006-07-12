#ifndef RADIO_SENSE_TO_LEDS_H
#define RADIO_SENSE_TO_LEDS_H

typedef nx_struct RadioSenseMsg {
  nx_uint16_t error;
  nx_uint16_t data;
} RadioSenseMsg;

enum {
  AM_RADIOSENSEMSG = 7,
};

#endif
