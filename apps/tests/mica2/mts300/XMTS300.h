#ifndef MTS_300_H
#define MTS_300_H

// data pacet struct
typedef struct Mts300Msg {
  uint16_t vref;
  uint16_t thermistor;
  uint16_t light;
  uint16_t mic;
  uint16_t accelX;
  uint16_t accelY;
  uint16_t magX;
  uint16_t magY;
} Mts300Msg;

enum {
  AM_MTS300MSG = 6,
};

#define ACCEL_AVERAGE_POINTS 3

#endif
