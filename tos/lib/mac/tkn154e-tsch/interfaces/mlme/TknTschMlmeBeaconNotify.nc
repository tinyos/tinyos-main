/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 *
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

// TODO The indication event probably shouldn't need a return type

#include "tkntsch_types.h"

interface TknTschMlmeBeaconNotify
{

  /**
   * The MLME-BEACON-NOTIFY.indication primitive is used to send parameters contained
   * within a beacon frame or an enhanced beacon frame received by the MAC sublayer to
   * the next higher layer when either macAutoRequest is set to FALSE or when the beacon
   * frame contains one or more octets of payload. The primitive also sends a measure of
   * the LQI and the time the beacon frame was received. When an enhanced beacon is
   * received, the SDU contains a list of IEs, and Superframe Specification, GTS fields,
   * PendingAdd, and beacon Payload parameters are not present.
   *
   * @param SDU    The set of octets comprising the beacon payload including
   *               Payload IEs if present.
   *
   * @return       Return a message_t that must not be used by the upper layer anymore.
   *
   *
   *  The fields defined in IEEE 802.15.4 "BSN", "PANDescriptor", "PendAddrSpec" and
   *  "AddrList" are neglected here, since not relevant for TSCH.
   */
  event message_t* indication  (
                          message_t* beaconFrame
                        );
}
