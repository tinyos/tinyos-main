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
 * SPI Configuration for the SAM3U-EK devkit. Does not use DMA (PDC) at this
 * point. Byte interface performs busy wait!
 *
 * @author Thomas Schmid
 * @author Kevin Klues
 */

#include <sam3spihardware.h>

configuration HilSam3SpiC
{
    provides
    {
        interface Resource[uint8_t];
        interface SpiByte[uint8_t];
        interface FastSpiByte[uint8_t];
        interface SpiPacket[uint8_t];
        interface HplSam3SpiChipSelConfig[uint8_t];
        interface HplSam3SpiConfig;
    }
    uses {
        interface Init as SpiChipInit;
        interface ResourceConfigure[uint8_t];
    }
}
implementation
{
    components RealMainP;
    RealMainP.PlatformInit -> HilSam3SpiP.Init;

    components HplSam3SpiC;
    HplSam3SpiConfig = HplSam3SpiC;
    HilSam3SpiP.SpiChipInit = SpiChipInit;
    HilSam3SpiP.HplSam3SpiConfig  -> HplSam3SpiC;
    HilSam3SpiP.HplSam3SpiControl -> HplSam3SpiC;
    HilSam3SpiP.HplSam3SpiStatus  -> HplSam3SpiC;
    HilSam3SpiP.HplSam3SpiInterrupts -> HplSam3SpiC;
    HplSam3SpiChipSelConfig[0] =  HplSam3SpiC.HplSam3SpiChipSelConfig0;
    HplSam3SpiChipSelConfig[1] =  HplSam3SpiC.HplSam3SpiChipSelConfig1;
    HplSam3SpiChipSelConfig[2] =  HplSam3SpiC.HplSam3SpiChipSelConfig2;
    HplSam3SpiChipSelConfig[3] =  HplSam3SpiC.HplSam3SpiChipSelConfig3;

    components new FcfsArbiterC(SAM3_SPI_BUS) as ArbiterC;
    Resource = ArbiterC;
    ResourceConfigure = ArbiterC;
    HilSam3SpiP.ArbiterInfo -> ArbiterC;

    components new AsyncStdControlPowerManagerC() as PM;
    PM.AsyncStdControl -> HplSam3SpiC;
    PM.ArbiterInfo -> ArbiterC.ArbiterInfo;
    PM.ResourceDefaultOwner -> ArbiterC.ResourceDefaultOwner;

    components HilSam3SpiP;
    SpiByte = HilSam3SpiP.SpiByte;
    SpiPacket = HilSam3SpiP.SpiPacket;

    components new FastSpiSam3C(SAM3_SPI_BUS);
    FastSpiSam3C.SpiByte -> HilSam3SpiP.SpiByte;
    FastSpiByte = FastSpiSam3C;

    components HplSam3uGeneralIOC;
    HilSam3SpiP.SpiPinMiso -> HplSam3uGeneralIOC.HplPioA13;
    HilSam3SpiP.SpiPinMosi -> HplSam3uGeneralIOC.HplPioA14;
    HilSam3SpiP.SpiPinSpck -> HplSam3uGeneralIOC.HplPioA15;

    components HplNVICC;
    HilSam3SpiP.SpiIrqControl -> HplNVICC.SPI0Interrupt;
}
