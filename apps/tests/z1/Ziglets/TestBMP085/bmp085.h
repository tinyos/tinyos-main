#ifndef BMP085_H
#define BMP085_H

// Address, R/W, CTL
  
#define BMP085_ADDR 0x77
#define BMP085_ADDR_READ 0xEF
#define BMP085_ADDR_WRITE 0xEE
#define BMP085_CTLREG 0xF4

// Read commands

#define BMP085_UT_NOSRX 0x2E  // 4.5ms
#define BMP085_UP_OSRS0 0x34  // 4.5ms
#define BMP085_UP_OSRS1 0x74  // 4.5ms
#define BMP085_UP_OSRS2 0xB4  // 13.5ms
#define BMP085_UP_OSRS3 0xF4  // 25.5ms

// Data Registers (read from)

#define BMP085_DATA_MSB  0xF6
#define BMP085_DATA_LSB  0xF7
#define BMP085_DATA_XLSB 0xF8

// EEPROM Calibration registers

#define BMP085_AC1_MSB  0xAA
#define BMP085_AC1_LSB  0xAB
#define BMP085_AC2_MSB  0xAC
#define BMP085_AC2_LSB  0xAD
#define BMP085_AC3_MSB  0xAE
#define BMP085_AC3_LSB  0xAF
#define BMP085_AC4_MSB  0xB0
#define BMP085_AC4_LSB  0xB1
#define BMP085_AC5_MSB  0xB2
#define BMP085_AC5_LSB  0xB3
#define BMP085_AC6_MSB  0xB4
#define BMP085_AC6_LSB  0xB5
#define BMP085_B1_MSB   0xB6
#define BMP085_B1_LSB   0xB7
#define BMP085_B2_MSB   0xB8
#define BMP085_B2_LSB   0xB9
#define BMP085_MB_MSB   0xBA
#define BMP085_MB_LSB   0xBB
#define BMP085_MC_MSB   0xBC
#define BMP085_MC_LSB   0xBD
#define BMP085_MD_MSB   0xBE
#define BMP085_MD_LSB   0xBF

// Ultra low power mode
// Oversampling = 0, internal samples = 1, conversion press = 4.5ms
// Current = 3uA/sample, RMS noise = 0.06hPa

// Reading
// UP = pressure data (16 or 19 bits)
// UT = Temp (16 bit)

// EOC = end of conversion
// XCLR = reset (1 pulso 1us)

// Start -> Meas UT -> 4.5ms -> Read UT -> Meas UP -> 4.5ms -> Read UP

enum {
  BMPCMD_IDLE = 0,
  BMPCMD_START,
  BMPCMD_READ_CALIB,
  BMPCMD_READ_UT,
  BMPCMD_READ_UP,
  BMPCMD_READ_TEMP,
  BMPCMD_READ_PRES,
} BMP085_CMD;


#endif
