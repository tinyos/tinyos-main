#ifndef UCMINISENSOR_H
#define UCMINISENSOR_H
typedef struct measurement {
  uint32_t press;
  uint32_t temp2;
  uint16_t temp;
  uint16_t humi;
  uint16_t light;
  uint16_t temp3;
  uint16_t voltage;
  uint16_t dummy;//MIG bug?
} measurement_t;

typedef struct calib {
  uint16_t coefficient[6];
} calib_t;

enum{
  AM_MEASUREMENT = 10,
  AM_CALIB = 11,
};
#endif