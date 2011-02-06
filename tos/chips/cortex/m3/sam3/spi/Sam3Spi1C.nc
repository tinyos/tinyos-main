/**
 * Copyright (c) 2009 The Regents of the University of California.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues
 */

#include <sam3spihardware.h>

generic configuration Sam3Spi1C()
{
    provides
    {
        interface Resource;
        interface SpiByte;
	interface FastSpiByte;
        interface SpiPacket;
	interface HplSam3SpiChipSelConfig;
    }
    uses {
        interface Init as SpiInit;
        interface ResourceConfigure;
    }
}
implementation
{
    enum {
      CLIENT_ID = unique(SAM3_SPI_BUS),
    };

    components HilSam3SpiC as SpiC;
    SpiC.SpiChipInit = SpiInit;
    Resource = SpiC.Resource[CLIENT_ID];
    SpiByte = SpiC.SpiByte[CLIENT_ID];
    FastSpiByte = SpiC.FastSpiByte[CLIENT_ID];
    SpiPacket = SpiC.SpiPacket[CLIENT_ID];
    HplSam3SpiChipSelConfig = SpiC.HplSam3SpiChipSelConfig[1];
    
    components new Sam3SpiP(1);
    ResourceConfigure = Sam3SpiP.ResourceConfigure;
    Sam3SpiP.SubResourceConfigure <- SpiC.ResourceConfigure[CLIENT_ID];
    Sam3SpiP.HplSam3SpiConfig -> SpiC.HplSam3SpiConfig;
}

