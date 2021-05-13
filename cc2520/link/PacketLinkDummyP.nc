/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Dummy module for Packet Link layer
 * @author David Moss
 * @author Jon Wyant
 */

module PacketLinkDummyP {
  provides {
    interface PacketLink;
  }
  
  uses {
    interface PacketAcknowledgements;
  }
}

implementation {
  
  /***************** PacketLink Commands ***************/
  /**
   * Set the maximum number of times attempt message delivery
   * Default is 0
   * @param msg
   * @param maxRetries the maximum number of attempts to deliver
   *     the message
   */
  command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
  }

  /**
   * Set a delay between each retry attempt
   * @param msg
   * @param retryDelay the delay betweeen retry attempts, in milliseconds
   */
  command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) {
  }

  /** 
   * @return the maximum number of retry attempts for this message
   */
  command uint16_t PacketLink.getRetries(message_t *msg) {
    return 0;
  }

  /**
   * @return the delay between retry attempts in ms for this message
   */
  command uint16_t PacketLink.getRetryDelay(message_t *msg) {
    return 0;
  }

  /**
   * @return TRUE if the message was delivered.
   *     This should always be TRUE if the message was sent to the
   *     AM_BROADCAST_ADDR
   */
  command bool PacketLink.wasDelivered(message_t *msg) {
    return call PacketAcknowledgements.wasAcked(msg);
  }
}

