#ifndef DS2411_H
#define DS2411_H

#define DS2411_READ_ADDR 0x33

enum {
  DS2411_SERIAL_LENGTH = 6,
  DS2411_DATA_LENGTH = 8
};

typedef union ds241_serial_t {
  uint8_t data[DS2411_DATA_LENGTH];
  struct {
    uint8_t family_code;
    uint8_t serial[DS2411_SERIAL_LENGTH];
    uint8_t crc;
  };
} ds2411_serial_t;

#endif
