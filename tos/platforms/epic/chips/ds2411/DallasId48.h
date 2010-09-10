/* -*- mode:c++; indent-tabs-mode: nil -*- */
/**
 * data structures for dallas/maxim serial ID chips
 */
/*
 * @author Andreas Koepke
 */

#ifndef DALLASID48_H
#define DALLASID48_H

enum {
    DALLASID48_SERIAL_LENGTH = 6,
    DALLASID48_DATA_LENGTH = 8
};

typedef union dallasid48_serial_t {
    uint8_t data[DALLASID48_DATA_LENGTH];
    struct {
        uint8_t family_code;
        uint8_t serial[DALLASID48_SERIAL_LENGTH];
        uint8_t crc;
    };
} dallasid48_serial_t;

// The CRC polynomial is X^8 + X^5 + X^4 + 1,
// code is taken from http://linux.die.net/man/3/_crc_ccitt_update

bool dallasid48checkCrc(const dallasid48_serial_t *id) {
    uint8_t crc = 0;
    uint8_t idx;
    for(idx = 0; idx < DALLASID48_DATA_LENGTH; idx++) {
        uint8_t i;
        crc = crc ^ (*id).data[idx];
        for(i = 0; i < 8; i++) {
            if(crc & 0x01) {
                crc = (crc >> 1) ^ 0x8C;
            }
            else {
                crc >>= 1;
            }
        }
    }
    return crc == 0;
}

/* test application 

   #include <stdio.h>
   #include <stdlib.h>
   #include <stdint.h>
   #ifndef bool
   #define bool uint8_t 
   #endif
   #include "DallasId48.h"
   
   int main(void) {
        dallasid48_serial_t id = { 0x02, 0x1C, 0xB8, 0x01, 0x00, 0x00, 0x00, 0xA2};
        printf("fam: %x, crc: %x, crc ok: %i\n", id.family_code, id.crc, dallasid48checkCrc(&id));
   }

*/

#endif // DALLASID48_H
