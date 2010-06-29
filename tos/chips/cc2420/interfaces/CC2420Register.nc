/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * Interface representing one of the Read/Write registers on the
 * CC2420 radio. The return values (when appropriate) refer to the
 * status byte returned on the CC2420 SO pin. A full list of RW
 * registers can be found on page 61 of the CC2420 datasheet (rev
 * 1.2). Page 25 of the same document describes the protocol for
 * interacting with these registers over the CC2420 SPI bus.
 *
 * @author Philip Levis
 * @version $Revision: 1.3 $ $Date: 2010-06-29 22:07:44 $
 */

#include "CC2420.h"

interface CC2420Register {

  /**
   * Read a 16-bit data word from the register.
   *
   * @param data pointer to place the register value.
   * @return status byte from the read.
   */
  async command cc2420_status_t read(uint16_t* data);

  /**
   * Write a 16-bit data word to the register.
   * 
   * @param data value to write to register.
   * @return status byte from the write.
   */
  async command cc2420_status_t write(uint16_t data);

}
