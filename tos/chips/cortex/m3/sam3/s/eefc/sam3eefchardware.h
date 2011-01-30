#ifndef SAM3SEEFCHARDWARE_H
#define SAM3SEEFCHARDWARE_H

#include "eefchardware.h"

/**
 * Memory mapping for the EEFC0. No EEFC1 on the Sam3S.
 */
volatile eefc_t* EEFC0 = (volatile eefc_t*) 0x400E0A00; // EEFC0 Base Address

#endif // SAM3SEEFCHARDWARE_H
