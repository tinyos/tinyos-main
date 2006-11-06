/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.2 $ $Date: 2006-11-06 11:57:08 $
 */

interface CC2420Packet {
  
  /**
   * Get transmission power setting for current packet.
   *
   * @param the message
   */
  async command uint8_t getPower( message_t* p_msg );

  /**
   * Set transmission power for a given packet. Valid ranges are
   * between 0 and 31.
   *
   * @param p_msg the message.
   * @param power transmission power.
   */
  async command void setPower( message_t* p_msg, uint8_t power );
  
  /**
   * Get rssi value for a given packet. For received packets, it is
   * the received signal strength when receiving that packet. For sent
   * packets, it is the received signal strength of the ack if an ack
   * was received.
   */
  async command int8_t getRssi( message_t* p_msg );

  /**
   * Get lqi value for a given packet. For received packets, it is the
   * link quality indicator value when receiving that packet. For sent
   * packets, it is the link quality indicator value of the ack if an
   * ack was received.
   */
  async command uint8_t getLqi( message_t* p_msg );
  
}
