
#ifndef TESTSENSOR_H
#define TESTSENSOR_H
  
#define TSL2563_ADDRESS		0x39

#define TSL256X_CONTROL_POWER_ON (0x3)
#define TSL256X_CONTROL_POWER_OFF (0x0)

#define TSL256X_PTR_CONTROL	(0x0)

#define TSL256X_COMMAND_CMD	(1<<7)
#define TSL256X_COMMAND_CLEAR	(1<<6)
#define TSL256X_COMMAND_WORD	(1<<5)
#define TSL256X_COMMAND_BLOCK	(1<<4)
#define TSL256X_COMMAND_ADDRESS(_x) ((_x) & 0xF)

#define TSL256X_PTR_DATA0LOW	(0xC)
#define TSL256X_PTR_DATA0HIGH	(0xD)
#define TSL256X_PTR_DATA1LOW	(0xE)
#define TSL256X_PTR_DATA1HIGH	(0xF)

#define K1T 0X0040
#define B1T 0x01f2
#define M1T 0x01b2

#define K2T 0x0080
#define B2T 0x0214
#define M2T 0x02d1

#define K3T 0x00c0
#define B3T 0x023f
#define M3T 0x037b

#define K4T 0x0100
#define B4T 0x0270
#define M4T 0x03fe

#define K5T 0x0138
#define B5T 0x016f
#define M5T 0x01fc

#define K6T 0x019a
#define B6T 0x00d2
#define M6T 0x00fb

#define K7T 0x029a
#define B7T 0x0018
#define M7T 0x0012

#define K8T 0x029a
#define B8T 0x0000
#define M8T 0x0000

enum {
TSLCMD_IDLE = 0,
TSLCMD_START,
TSLCMD_READ,
TSLCMD_STOP,
} CMD;


#endif
