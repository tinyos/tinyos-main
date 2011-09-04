#ifndef SHT21_H
#define SHT21_H

enum {
  TRIGGER_T_MEASUREMENT_HOLD_MASTER	=	0xE3,
  TRIGGER_RH_MEASUREMENT_HOLD_MASTER	=	0xE5,
  TRIGGER_T_MEASUREMENT_NO_HOLD_MASTER	=	0xF3,
  TRIGGER_RH_MEASUREMENT_NO_HOLD_MASTER	=	0xF5,
  WRITE_USER_REGISTER			=	0xE6,
  READ_USER_REGISTER			=       0xE7,
  SOFT_RESET                            =       0xFE,
} Sht21Command;

enum {
  RESOLUTION_12_14BIT	=	0x00,   //humidity _ , temperature _
  RESOLUTION_8_12BIT	=	0x01,
  RESOLUTION_10_13BIT	=	0x80,
  RESOLUTION_11_11BIT	=	0x81,
} Sht21Resolution;

enum {
  HEATER_ON     =       0x04,
  HEATER_OFF    =       0x00,
} Sht21Heater;

enum {
  I2C_ADDRESS =  64,
} Sht21Header;

enum {
  TIMEOUT_14BIT =       85,//85,
  TIMEOUT_13BIT =       43,
  TIMEOUT_12BIT =       22,//22,
  TIMEOUT_11BIT =       11,//11,
  TIMEOUT_10BIT =       6,//6,
  TIMEOUT_8BIT  =       3,//3,
  TIMEOUT_RESET =       15,
} Sht21Timeout;

#endif
