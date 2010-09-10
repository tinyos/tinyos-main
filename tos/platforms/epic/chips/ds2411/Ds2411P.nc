/* -*- mode:c++; indent-tabs-mode: nil -*- */
/**
 * DS2411 telosb tmote sky serial id
 */
/**
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 */

#include "DallasId48.h"

module Ds2411P {
    provides {
        interface ReadId48;
    }
    uses {
        interface OneWireStream as OneWire;
    }
}
implementation {
    bool haveId = FALSE;
    dallasid48_serial_t ds2411id;

    error_t readId() {
        error_t e = call OneWire.read(0x33, ds2411id.data, DALLASID48_DATA_LENGTH);
        if(e == SUCCESS) {
            if(dallasid48checkCrc(&ds2411id)) {
                haveId = TRUE;
            }
            else {
                e = EINVAL;
            }
        }
        return e;
    }
    
    command error_t ReadId48.read(uint8_t *id) {
        error_t e = SUCCESS;
        if(!haveId) {
            e = readId();
        }
        if(haveId) {
            uint8_t i;
            for(i = 0; i < DALLASID48_SERIAL_LENGTH; i++) {
                id[i] = ds2411id.serial[i];
            }
        }
        return e;
    }
}
