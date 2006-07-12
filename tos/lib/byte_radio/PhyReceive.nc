/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include <TinyError.h>
#include <message.h>

/**
 * This interface is similar to the Receive interface.
 *   
 * The interface provides two events in async context which indicate that
 * a packet is detected or was received. It is provided by the Phy layer
 * of byte radios.
 *
 * @see Receive
 *
 * @author Philipp Huppertz
 */ 

interface PhyReceive {
   /**
   * Receive a packet buffer, returning a buffer for the signaling
   * component to use for the next reception. The return value
   * can be the same as <tt>msg</tt>, as long as the handling
   * component copies out the data it needs. The <tt>msg</tt> may
   * be invalid when <tt>error</tt> is not SUCCESS !
   *
   * <b>Note</b> that misuse of this interface is one of the most
   * common bugs in TinyOS code. For example, if a component both calls a
   * send on the passed message and returns it, then it is possible
   * the buffer will be reused before the send occurs, overwriting
   * the component's data. This would cause the mote to possibly
   * instead send a packet it most recently received.
   *
   * @param  msg      the received packet
   * @param  payload  a pointer to the packet's payload
   * @param  len      the length of the data region pointed to by payload
   * @param  error    FAIL if the packet was corrupted (e.g. wrong crc)
   * @return          a packet buffer for the stack to use for the next
   *                  received packet.
   */
  async event message_t* receiveDone(message_t* msg, void* payload, uint8_t len, error_t error);

  /**
  * Indicates that a packet has been detected. This means that the packet's physical header
  * (preamble bytes + sync byte + SFD byte) was received.
  *
  */
  async event void receiveDetected();
  
}
