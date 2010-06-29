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
 * A byte-level communication interface for byte radios.
 * It signals byte receptions and
 * provides a split-phased byte send interface. txByteReady states
 * that the component can accept another byte in its queue to send,
 * while txDone states that the send queue has been emptied.
 *
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */
interface RadioByteComm {
  /**
   * Transmits a byte over the radio.
   *
   * @param data The byte to be transmitted.
   */
  async command void txByte(uint8_t data);
	
  /**
   * Notification that the radio is ready to receive another byte.
   *
   * @param data The byte read from the radio.
   */
  async event void rxByteReady(uint8_t data);

  /**
   * Notification that the bus is ready to transmit/queue another byte.
   *
   * @param error Success Notification of the successful transmission of the last byte.
   */
  async event void txByteReady(error_t error);

  /**
   * Check to see if the transmission is done and the queue is empty
   *
   * @return TRUE if the queue is empty and no more bytes will be sent.
   *         FALSE if bytes remain in the queue.
   */
  async command bool isTxDone();
}
