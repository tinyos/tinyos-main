/* Copyright (c) 2010 People Power Co.
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
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

#include "ppp.h"

/** Provides common support for a protocol that uses LCP-style code-based handlers.
 *
 * @param Protocol the Protocol code for which this component coordinates
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
generic module PppProtocolCodeCoordinatorP (uint16_t Protocol) {
  provides {
    interface PppProtocolCodeCoordinator;
  }
  uses {
    interface Ppp;
    interface PppProtocolCodeSupport as CodeHandler[ uint8_t code ];
  }
} implementation {

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t result) { }

  /** The unique identifier to be used in the next Protocol-Reject
   * packet generated. */
  uint8_t id_protocolReject;

  /** The unique identifier to be used in the next Code-Reject packet
   * generated. */
  uint8_t id_codeReject;

  command error_t PppProtocolCodeCoordinator.rejectPacket (unsigned int rejected_protocol,
                                                           const uint8_t* ip,
                                                           const uint8_t* ipe,
                                                           frame_key_t* keyp)
  {
    const uint8_t* fpe = 0;
    frame_key_t key;
    uint8_t* fp = call Ppp.getOutputFrame(Protocol, &fpe, TRUE, &key);
    const uint8_t* frame_start = fp;
    uint8_t* lp;
    error_t rc;

    if (0 == fp) {
      return EBUSY;
    }
    
    /** TODO: Test this with rejected frames around MRU limit */
    if (0 != rejected_protocol) {
      *fp++ = PppControlProtocolCode_ProtocolReject;
      *fp++ = id_protocolReject++;
    } else {
      *fp++ = PppControlProtocolCode_CodeReject;
      *fp++ = id_codeReject++;
    }
    /* Skip over the length field for now */
    lp = fp;
    fp += 2;
    if (0 != rejected_protocol) {
      /* Store the rejected protocol in two octets */
      *fp++ = (rejected_protocol >> 8);
      *fp++ = (rejected_protocol & 0x0FF);
    }

    /* Fill out as much of the frame as necessary with as much of the
     * information field as will fit. */
    while ((fp < fpe) && (ip < ipe)) {
      *fp++ = *ip++;
    }

    /* Go back and store the length field */
    {
      unsigned int len = (fp - frame_start);
      *lp++ = (len >> 8);
      *lp++ = (len & 0x0FF);
    }

    rc = call Ppp.fixOutputFrameLength(key, fp);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }
    if ((SUCCESS == rc) && keyp) {
      *keyp = key;
    }
    return rc;
  }
                        
  command error_t PppProtocolCodeCoordinator.dispatch (const uint8_t* information,
                                                       unsigned int information_length)
  {
    const uint8_t* ip = information;
    const uint8_t* ipe = ip + information_length;
    uint8_t code = *ip++;
    uint8_t identifier = *ip++;
    uint16_t length = ((ip[0] << 8) + ip[1]);
    ip += 2;

    /* Decrease the length by space used by the fixed header we've
     * already consumed. */
    length -= 4;
    
    if (0 == call CodeHandler.getCode[code]()) {
      return call PppProtocolCodeCoordinator.rejectPacket(0, information, ipe, 0);
    }
    return call CodeHandler.process[code](identifier, ip, ipe);
  }

  default command uint8_t CodeHandler.getCode[ uint8_t code ] () { return 0; }

  default command error_t CodeHandler.process[ uint8_t code ] (uint8_t identifier,
                                                               const uint8_t* data,
                                                               const uint8_t* data_end) { return FAIL; }
}
