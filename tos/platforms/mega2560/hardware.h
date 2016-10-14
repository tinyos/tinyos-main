#ifndef HARDWARE_H
#define HARDWARE_H

#ifndef MHZ
/** Clock rate for mega2560 is ~16MHz except if overruled by user 
 *  (this value must be a power of 2, see MicaTimer.h and MeasureClockC.nc) 
 */
#define MHZ 16
#endif

#include <atm128hardware.h>
#include "MicaTimer.h"

#ifndef PLATFORM_MHZ
#define PLATFORM_MHZ  16
#endif

// enum so components can override power saving,
// as per TEP 112.
// As this is not a real platform, just set it to 0.
enum {
	TOS_SLEEP_NONE = ATM128_POWER_IDLE,
};

#ifndef PLATFORM_BAUDRATE 
#define PLATFORM_BAUDRATE 57600L
#endif

#endif // HARDWARE_H

