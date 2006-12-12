/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 */
 
/**
 * Interface that helps the MAC to cooperate with the routing
 * @author Andreas Koepke (koepke at tkn.tu-berlin.de)
 */ 
interface Teamgeist {
    /**
     * Get the AM type of the messages that are jointly routed by the MAC and
     * the routing layer. Only for these messages the MAC tries to access the
     * routing layer. 
     */
    event am_id_t observedAMType();

    /**
     * The MAC layer uses this function to ask the routing protocol whether it
     * should acknowledge and thus propose himself as a forwarder. 
     */
    async event bool needsAck(message_t *msg, am_addr_t src, am_addr_t dest, uint16_t snr);

    /**
     * Sending the message to the original destination did not work.
     * Ask for a different one.
     */
    async event am_addr_t getDestination(message_t *msg, uint8_t retryCounter);
    
    /**
     * Information on the ACK.
     */
    async event void gotAck(message_t *msg, am_addr_t ackSender, uint16_t snr);

    /**
     * The MAC layer uses this function to ask the routing protocol how many
     * potential forwarders there are. This may not give a precise number, but
     * a rough estimate.
     */
    async event uint8_t estimateForwarders(message_t *msg);
}
