// $Id: HplCC1000Spi.nc,v 1.6 2010-06-29 22:07:44 scipio Exp $

/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
