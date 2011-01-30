/*
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 */

#include "AT91SAM3U4.h"
#include "sam3eefchardware.h"

configuration Sam3EefcC {
  provides {
    interface Init as InitIFlash0;
    interface Init as InitIFlash1;
    interface InternalFlash as InternalFlash0;
    interface InternalFlash as InternalFlash1;
  }
}
implementation {
  components new HplSam3EefcC((uint32_t)AT91C_BASE_EFC0, AT91C_IFLASH0, 
                               AT91C_IFLASH0_PAGE_SIZE, AT91C_IFLASH0_SIZE) as IFlash0;
  components new HplSam3EefcC((uint32_t)AT91C_BASE_EFC1, AT91C_IFLASH1, 
                               AT91C_IFLASH1_PAGE_SIZE, AT91C_IFLASH1_SIZE) as IFlash1;
  InitIFlash0 = IFlash0;
  InitIFlash1 = IFlash1;
  InternalFlash0 = IFlash0;
  InternalFlash1 = IFlash1;
}
