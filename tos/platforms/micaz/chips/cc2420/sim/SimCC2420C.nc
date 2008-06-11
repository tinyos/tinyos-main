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
 * Simulated implementation of the CC2420 radio chip. It is an
 * SPI end point, and also signals some interrupts/GPIO pins.\
 * This is a pretty complicated component, so be aware that it
 * may be very helpful to have the CC2420 data sheet nearby.
 *
 * @author Philip Levis
 * @date   November 22 2005
 */

module SimCC2420C {

  provides {
    interface Init;
    interface Resource[uint8_t] as SpiResource;
    interface SPIByte;
    interface SPIPacket;
    interface GeneralIO as CCA;
    interface GeneralIO as CSN;
    interface GeneralIO as FIFO;
    interface GeneralIO as FIFOP;
    interface GeneralIO as RSTN;
    interface GeneralIO as SFD;
    interface GeneralIO as VREN;
    interface GpioCapture as CaptureSFD;
    interface GpioInterrupt as InterruptFIFOP;
  }
  
  uses {
    interface Resource[uint8_t] as SubSpiResource;
    interface ArbiterInfo as SpiUser;
    interface McuPowerState;
  }

  
}

implementation {

  
  
}
