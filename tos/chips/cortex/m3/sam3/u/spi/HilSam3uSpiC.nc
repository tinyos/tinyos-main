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

#include <sam3uspihardware.h>

configuration HilSam3uSpiC
{
    provides
    {
        interface Resource[uint8_t];
        interface SpiByte[uint8_t];
	interface FastSpiByte[uint8_t];
        interface SpiPacket[uint8_t];
	interface HplSam3uSpiChipSelConfig[uint8_t];
	interface HplSam3uSpiConfig;
    }
    uses {
        interface Init as SpiChipInit;
        interface ResourceConfigure[uint8_t];
    }
}
implementation
{
    components RealMainP;
    RealMainP.PlatformInit -> HilSam3uSpiP.Init;

    components HplSam3uSpiC;
    HplSam3uSpiConfig = HplSam3uSpiC;
    HilSam3uSpiP.SpiChipInit = SpiChipInit;
    HilSam3uSpiP.HplSam3uSpiConfig -> HplSam3uSpiC;
    HilSam3uSpiP.HplSam3uSpiControl -> HplSam3uSpiC;
    HilSam3uSpiP.HplSam3uSpiStatus -> HplSam3uSpiC;
    HilSam3uSpiP.HplSam3uSpiInterrupts -> HplSam3uSpiC;
    HplSam3uSpiChipSelConfig[0] =  HplSam3uSpiC.HplSam3uSpiChipSelConfig0;
    HplSam3uSpiChipSelConfig[1] =  HplSam3uSpiC.HplSam3uSpiChipSelConfig1;
    HplSam3uSpiChipSelConfig[2] =  HplSam3uSpiC.HplSam3uSpiChipSelConfig2;
    HplSam3uSpiChipSelConfig[3] =  HplSam3uSpiC.HplSam3uSpiChipSelConfig3;

    components new FcfsArbiterC(SAM3U_SPI_BUS) as ArbiterC;
    Resource = ArbiterC;
    ResourceConfigure = ArbiterC;
    HilSam3uSpiP.ArbiterInfo -> ArbiterC;

    components new AsyncStdControlPowerManagerC() as PM;
    PM.AsyncStdControl -> HplSam3uSpiC;
    PM.ArbiterInfo -> ArbiterC.ArbiterInfo;
    PM.ResourceDefaultOwner -> ArbiterC.ResourceDefaultOwner;

    components HilSam3uSpiP;
    SpiByte = HilSam3uSpiP.SpiByte;
    SpiPacket = HilSam3uSpiP.SpiPacket;

    components new FastSpiSam3uC(SAM3U_SPI_BUS);
    FastSpiSam3uC.SpiByte -> HilSam3uSpiP.SpiByte;
    FastSpiByte = FastSpiSam3uC;

    components HplSam3uGeneralIOC;
    HilSam3uSpiP.SpiPinMiso -> HplSam3uGeneralIOC.HplPioA13;
    HilSam3uSpiP.SpiPinMosi -> HplSam3uGeneralIOC.HplPioA14;
    HilSam3uSpiP.SpiPinSpck -> HplSam3uGeneralIOC.HplPioA15;

    components HplNVICC;
    HilSam3uSpiP.SpiIrqControl -> HplNVICC.SPI0Interrupt;
}
