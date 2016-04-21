#ifndef HARDWARE_H
#define HARDWARE_H

#include <atm128hardware.h>

#ifndef PLATFORM_MHZ
#define PLATFORM_MHZ  16
#endif

// enum so components can override power saving,
// as per TEP 112.
// As this is not a real platform, just set it to 0.
enum {
	TOS_SLEEP_NONE = 0,
};

#ifndef PLATFORM_BAUDRATE 
#define PLATFORM_BAUDRATE 57600L
#endif

#endif // HARDWARE_H

