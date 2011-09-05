/*
 * Copyright (c) 2011, University of Szeged
 * All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 * Author: Zsolt Szabo
 */

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
