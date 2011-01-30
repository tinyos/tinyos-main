#ifndef SAM3UEEFCHARDWARE_H
#define SAM3UEEFCHARDWARE_H

#include "eefchardware.h"

/**
 * Memory mapping for the EEFC0 and EEFC1 (SAM3U/4E only!)
 */
volatile eefc_t* EEFC0 = (volatile eefc_t*) 0x400E0800; // EEFC0 Base Address
volatile eefc_t* EEFC1 = (volatile eefc_t*) 0x400E0A00; // EEFC1 Base Address

#endif // SAM3UEEFCHARDWARE_H
