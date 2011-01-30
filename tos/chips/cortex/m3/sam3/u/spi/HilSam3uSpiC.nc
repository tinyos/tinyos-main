/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
