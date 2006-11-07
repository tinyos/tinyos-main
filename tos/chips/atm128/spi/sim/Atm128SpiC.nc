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
 */

/**
 * The simulated HAL of the SPI bus on the atm128, which just maps to
 * the platform-specific implementation of the device end point.
 *
 * <pre>
 *  $Id: Atm128SpiC.nc,v 1.3 2006-11-07 19:30:45 scipio Exp $
 * </pre>
 *
 *
 * @author Philip Levis
 * @date   November 22 2005
 */

configuration Atm128SpiC {
  provides interface Init;
  provides interface SPIByte;
  provides interface SPIPacket;
  provides interface Resource[uint8_t id];
}
implementation {
  components SimAtm128SpiDeviceC as Device;
  components new SimpleFcfsArbiterC("Atm128SpiC.Resource") as Arbiter;
  components McuSleepC;
  
  Init         = Device;
  
  SPIByte      = Device;
  SPIPacket    = Device;
  Resource     = Arbiter;

  Device.McuPowerState   -> McuSleepC;
}
