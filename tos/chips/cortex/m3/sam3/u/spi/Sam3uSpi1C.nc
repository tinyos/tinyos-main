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
 * @author Kevin Klues
 */

#include <sam3uspihardware.h>

generic configuration Sam3uSpi1C()
{
    provides
    {
        interface Resource;
        interface SpiByte;
	interface FastSpiByte;
        interface SpiPacket;
	interface HplSam3uSpiChipSelConfig;
    }
    uses {
        interface Init as SpiInit;
        interface ResourceConfigure;
    }
}
implementation
{
    enum {
      CLIENT_ID = unique(SAM3U_SPI_BUS),
    };

    components HilSam3uSpiC as SpiC;
    SpiC.SpiChipInit = SpiInit;
    Resource = SpiC.Resource[CLIENT_ID];
    SpiByte = SpiC.SpiByte[CLIENT_ID];
    FastSpiByte = SpiC.FastSpiByte[CLIENT_ID];
    SpiPacket = SpiC.SpiPacket[CLIENT_ID];
    HplSam3uSpiChipSelConfig = SpiC.HplSam3uSpiChipSelConfig[1];
    
    components new Sam3uSpiP(1);
    ResourceConfigure = Sam3uSpiP.ResourceConfigure;
    Sam3uSpiP.SubResourceConfigure <- SpiC.ResourceConfigure[CLIENT_ID];
    Sam3uSpiP.HplSam3uSpiConfig -> SpiC.HplSam3uSpiConfig;
}

