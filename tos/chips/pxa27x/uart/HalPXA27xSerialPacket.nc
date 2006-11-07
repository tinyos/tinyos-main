/* $Id: HalPXA27xSerialPacket.nc,v 1.3 2006-11-07 19:31:14 scipio Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

/**
 * @author Phil Buonadonna
 */

#include "pxa27x_serial.h"

interface HalPXA27xSerialPacket
{
  /**
   * Begin transmission of a UART stream. If SUCCESS is returned,
   * <code>sendDone</code> will be signalled when transmission is
   * complete.
   *
   * @param buf Buffer for bytes to send.
   * @param len Number of bytes to send.
   * @return SUCCESS if request was accepted, FAIL otherwise.
   */
  async command error_t send(uint8_t *buf, uint16_t len);
  
  /**
   * Signal completion of sending a stream.
   *
   * @param buf Bytes sent.
   * @param len Number of bytes sent.
   * @param status UART error status.
   *
   * @return buf A pointer to a new buffer of equal length
   * as in the original <code>send</code> call that is to be transmitted (chained
   * send). Set to NULL to end further transmissions.
   */
  async event uint8_t *sendDone(uint8_t *buf, uint16_t len, uart_status_t status);

  /**
   * Begin reception of a UART stream. If SUCCESS is returned,
   * <code>receiveDone</code> will be signalled when reception is
   * complete.
   *
   * @param buf Buffer for received bytes.
   * @param len Number of bytes to receive.
   * @param timeout Timeout, in milliseconds, for receive operation
   *
   * @return SUCCESS if request was accepted, FAIL otherwise.
   */
  async command error_t receive(uint8_t *buf, uint16_t len, uint16_t timeout);

   /**
   * Signal completion of receiving a stream.
   *
   * @param buf Buffer for bytes received.
   * @param len Number of bytes received.
   * @param status UART error status
   *
   * @return buf A pointer to a new buffer of equal or greater length 
   * as in the original <code>receive</code> call in which it intiate a
   * new packet reception (chained receive). Set to NULL to terminate further
   * reception. 
   */
  async event uint8_t *receiveDone(uint8_t *buf, uint16_t len, uart_status_t status);
  
}

