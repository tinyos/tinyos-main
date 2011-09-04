#ifndef BMA180_H
#define BMA180_H

typedef struct bma180_data {
  int16_t bma180_accel_x;
  int16_t bma180_accel_y;
  int16_t bma180_accel_z;
  int8_t bma180_temperature;
  uint8_t bma180_short_timestamp;
} bma180_data_t;

enum {
  BMA_SAMPLING_TIME_MS = 64,
};

/* 0: low noise, higest current, full bandwidth(1200Hz)
   1: super low noise, highest current, reduced bandwidth (300Hz)
   2: ultra low noise, smaller current, reduced bandwidth (150Hz)
   3: Low power mode, lowest current, higher noise than other modes
*/
enum {
  BMA_MODE = 3,  
};

/*
    0: 1g   1: 1.5g   2: 2g
    3: 3g   4: 4g     5: 8g
    6: 16g  7: NA
*/
enum {
  BMA_RANGE = 2,
};

//helper array for retrieving data in milli g according to actual range selection
const double convRatio[7] = { .13f, .19f, .25f, .38f, .5f, .99f, 1.98f};

/*
  0: 10Hz      1: 20Hz     2: 40Hz
  3: 75Hz      4:150Hz     5:300Hz
  7:600Hz      7:1200Hz
  8: High pass 1Hz
  9: band pass 0.2 .. 300Hz
  10 .. 15:  NA
*/
enum {
  BMA_BW = 4,
};

enum {
  BMA_LAT_INT = 0,
  BMA_NEW_DATA_INT,
  BMA_ADV_INT,
  BMA_TAPSENS_INT,
  BMA_LOW_INT,
  BMA_HIGH_INT,
  BMA_SLOPE_INT,
  BMA_SLOPE_ALART,
};

enum {
  BMA_CTRL_REG3 = (1<<BMA_LAT_INT) | (1<<BMA_NEW_DATA_INT),
};
#endif
