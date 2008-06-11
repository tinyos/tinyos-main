/*                                                                      
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Configuration representing the SPI device of the CC2420 for the micaZ
 * platform. The basic mapping is this:
 *  <ul>
 *   <li>the platform independent chips/CC2420 maps to HplCC2420SpiC;</li>
 *   <li>HplCC2420SpiC on the micaZ maps to Atm128SpiC;</li>
 *   <li>under TOSSIM Atm128SpiC maps to SimAtm128SpiDeviceC;</li>
 *   <li>SimAtm128SpiDeviceC maps to the actual simulation implementation in micaz/chips/cc2420/sim</li>
 *  </ul>
 *
 * @author Philip Levis
 * @date   November 22 2005
 */

configuration SimAtm128SpiDeviceC {

  provides interface Init;
  provides interface Resource[uint8_t];
  provides interface SPIByte;
  provides interface SPIPacket;

  uses interface Resource as SubResource[uint8_t];
  uses interface ArbiterInfo;
  uses interface McuPowerState;
  
}

implementation {

  components SimCC2420C;

  Init = SimCC2420C;
  Resource = SimCC2420C.SpiResource;
  SPIByte = SimCC2420C;
  SPIPacket = SimCC2420C;

  SubResource = SimCC2420C.SubSpiResource;
  ArbiterInfo = SimCC2420C;
  McuPowerState = SimCC2420C;
  
}
