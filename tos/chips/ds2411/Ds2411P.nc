/* Driver for the DS2411 unique ID chip.
 *
 * @author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 * @author: Brad Campbell <bradjc@umich.edu>
 */

#include "ds2411.h"

module Ds2411P {
  provides {
    interface ReadId48;
  }
  uses {
    interface OneWireReadWrite as OneWire;
    interface StdControl as PowerControl;
  }
}
implementation {
  bool haveId = FALSE;
  ds2411_serial_t ds2411id;

  // The CRC polynomial is X^8 + X^5 + X^4 + 1,
  // code is taken from http://linux.die.net/man/3/_crc_ccitt_update
  bool ds2411_check_crc (const ds2411_serial_t *id) {
    uint8_t crc = 0;
    uint8_t idx;
    for (idx = 0; idx < DS2411_DATA_LENGTH; idx++) {
      uint8_t i;
      crc = crc ^ (*id).data[idx];
      for (i = 0; i < 8; i++) {
        if (crc & 0x01) {
          crc = (crc >> 1) ^ 0x8C;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc == 0;
  }

  error_t readId () {
    error_t e;

    e = call PowerControl.start();
    if (e != SUCCESS) return FAIL;

    e = call OneWire.read(DS2411_READ_ADDR,
                          ds2411id.data,
                          DS2411_DATA_LENGTH);
    call PowerControl.stop();

    if (e == SUCCESS) {
      if (ds2411_check_crc(&ds2411id)) {
        haveId = TRUE;
      } else {
        e = EINVAL;
      }
    }
    return e;
  }

  command error_t ReadId48.read (uint8_t *id) {
    error_t e = SUCCESS;
    if (!haveId) {
      e = readId();
    }
    if (haveId) {
      memcpy(id, ds2411id.serial, DS2411_SERIAL_LENGTH);
    }
    return e;
  }
}
