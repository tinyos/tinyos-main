/*
* Copyright (c) 2011, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Andras Biro
*/

#ifndef MS5607_H
#define MS5607_H

typedef struct {
  uint16_t coefficient[6];
} calibration_t;
/*
 * Precision dependent values: supply current/conversion time:
 * OSR=4096: 12.5uA/9.04ms 
 * OSR=2048: 6.3uA/4.54ms 
 * OSR=1024: 3.2uA/2.28ms 
 * OSR=512:  1.7uA/1.17ms 
 * OSR=256:  0.9uA/0.6ms 
 */
enum {
  MS5607_PRESSURE_256=8, //resolution RMS=0.13mbar
  MS5607_PRESSURE_512=6, //resolution RMS=0.084mbar
  MS5607_PRESSURE_1024=4, //resolution RMS=0.054mbar
  MS5607_PRESSURE_2048=2, //resolution RMS=0.036mbar
  MS5607_PRESSURE_4096=0, //resolution RMS=0.024mbar
  MS5607_TEMPERATURE_256=8<<4, //resolution RMS=0.012 C
  MS5607_TEMPERATURE_512=6<<4, //resolution RMS=0.008 C
  MS5607_TEMPERATURE_1024=4<<4, //resolution RMS=0.005 C
  MS5607_TEMPERATURE_2048=2<<4, //resolution RMS=0.003 C
  MS5607_TEMPERATURE_4096=0<<4, //resolution RMS=0.002 C
  MS5607_PRESSURE_MASK=0x0f,
} ms5607_precision;

#ifndef MS5607_PRECISION
#define MS5607_PRECISION 0 //maximum precision with both sensors
#endif

#define UQ_MS5607_RESOURCE "Ms5607.ReadResource"

#endif

