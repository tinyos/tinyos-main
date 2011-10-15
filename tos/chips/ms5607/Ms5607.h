#ifndef __MS5607_H__
#define __MS5607_H__
typedef struct {
  uint16_t coefficient[6];
} calibration;
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

#endif
