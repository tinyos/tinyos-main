/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * Copyright (c) 2012, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Phil Buonadonna
 * @author Philip Levis
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef _I2C_H
#define _I2C_H

/*
 * It would be nice to deprecate TI2CExtdAddr and TI2CBasicAddr
 * and replace them with TI2C7Bit and TI2C10Bit.
 *
 * But there is way too much code that uses TI2CBasicAddr and BasicAddr
 * and it would be a pain to fix all that.  Also adding a backward
 * compatible interface to code providing BasicAddr is a pain because
 * of the signalling.  More trouble than it is worth.
 *
 * So keep in mind that TI2CBasicAddr is really TI2C7Bit.
 */

/* nobody uses ExtdAddr (10 bit) address but define it anyway */
typedef struct { } TI2CExtdAddr;

/*
 * BasicAddr (7 bit addresses) is used all over the place.
 * so back filling isn't recommended.  New code should use
 * TI2C7Bit.  But that is also problematic.  If so stick with
 * TI2CBasicAddr.
 */
typedef struct { } TI2CBasicAddr;

typedef struct { } TI2C7Bit;
typedef struct { } TI2C10Bit;

typedef uint8_t i2c_flags_t;

enum {
  I2C_START   = 0x01,
  I2C_STOP    = 0x02,
  I2C_ACK_END = 0x04,
  I2C_RESTART = 0x08,
};


#endif /* _I2C_H */
