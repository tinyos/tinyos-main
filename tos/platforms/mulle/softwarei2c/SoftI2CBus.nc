/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Interface for a software I2C bus.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
interface SoftI2CBus
{
  /*
   * Initializes bus default state.
   */
  async command void init();
  
  /*
   * Turn the bus off.
   */
  async command void off();

  /*
   * Generates a start condition on the bus.
   */
  async command void start();

  /*
   * Generates a stop condition.
   */
  async command void stop();

  /*
   * Restarts a I2C bus transaction.
   */
  async command void restart();

  /*
   * Reads a byte from the I2C bus.
   *
   * @param ack If true ack the read byte else nack.
   * @return A byte from the bus.
   */
  async command uint8_t readByte(bool ack);

  /*
   * Writes a byte on th I2C bus.
   * Send the data( or address) C  and wait for acknowledge after finishing
   * sending it. Nonacknowledge sets ACK=0 and normal sending sets ACK=1.
   *
   * @param byte the byte to write.
   */
  async command void writeByte(uint8_t byte);
  
  /*
   * Master sends the ACK (LowLevel), working as a master-receiver.
   */
  async command void masterAck();

  /*
   * Master sends the NACK (HighLevel), working as a master-receiver.
   */
  async command void masterNack();
}
