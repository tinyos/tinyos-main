#ifndef _LIB6LOWPAN_INCLUDES_H
#define _LIB6LOWPAN_INCLUDES_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef PC
#include "blip-pc-includes.h"
// typedef uint16_t ieee154_saddr_t;
typedef uint16_t hw_pan_t;
enum {
  HW_BROADCAST_ADDR = 0xffff,
};
#else
#include "blip-tinyos-includes.h"
#endif

#include <Ieee154.h>

#include "nwbyte.h"
#include "iovec.h"
#include "6lowpan.h"

#endif
