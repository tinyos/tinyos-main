// $Id: HplCC1000Spi.nc,v 1.3 2006-11-07 19:30:45 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Interface to the CC1000 chip's serial bus. This isn't really an SPI,
 * but the mica2 interface was done using the Atmega128 SPI hardware. Hence
 * the name.
 *
 * @author Jaein Jeong
 * @author Philip buonadonna
 */
interface HplCC1000Spi
{
  /**
   * Write a byte to the CC1000 bus.
   * @param data Byte to write.
   */
  async command void writeByte(uint8_t data);

  /**
   * Is write buffer busy with the last transmission?
   * @return TRUE if the buffer is busy, FALSE otherwise.
   */
  async command bool isBufBusy();

  /**
   * Get the last byte received from the CC1000 bus.
   * @return Last byte received.
   */
  async command uint8_t readByte();

  /**
   * Enable dataReady events on every byte sent or received from the CC1000
   * bus. After this is called, dataReady events will be signaled every
   * 8 CC1000 data clocks.
   */
  async command void enableIntr();

  /**
   * Disable CC1000 bus interrupts.
   */
  async command void disableIntr();

  /**
   * Initialise the interface to the CC1000 bus.
   */
  async command void initSlave();

  /**
   * Switch the interface to the CC1000 bus "transmit" mode.
   */
  async command void txMode();

  /**
   * Switch the interface to the CC1000 bus to "receive" mode.
   */
  async command void rxMode();

  /**
   * If enableIntr() is called, this event will be signaled every 8 CC1000
   * data clocks. 
   * @param data In "receive" mode, the last value received from the CC1000 
   *   bus.
   */
  async event void dataReady(uint8_t data);
}
