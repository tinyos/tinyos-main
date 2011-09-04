#ifndef BH1750FVI_H
#define BH1750FVI_H

enum {
  POWER_DOWN	=	0x00,
  POWER_ON	=	0x01,
  RESET         =       0x07,
  CONT_H_RES    =       0x10,
  CONT_H2_RES   =       0x11,
  CONT_L_RES    =       0x13,
  ONE_SHOT_H_RES        =       0x20,
  ONE_SHOT_H2_RES       =       0x21,
  ONE_SHOT_L_RES        =       0x23,
} bh1750fviCommand;

enum {
  TIMEOUT_H_RES =       180, // max 180
  TIMEOUT_H2_RES=       180, // max 180
  TIMEOUT_L_RES =        16, // max 24
} bh1750fviTimeout;

enum {
  WRITE_ADDRESS =       0x23,//0x46,  //if addr== H then it would be 0xb8
  READ_ADDRESS  =       0x23,//0x47,  //                             0xb9     
} bh1750fviHeader;

#endif
