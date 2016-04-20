#ifndef HARDWARE_H
#define HARDWARE_H

// enum so components can override power saving,
// as per TEP 112.
// As this is not a real platform, just set it to 0.
enum {
	TOS_SLEEP_NONE = 0,
};

#endif // HARDWARE_H

