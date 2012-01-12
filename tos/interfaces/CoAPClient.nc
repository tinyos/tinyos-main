/*
 * Copyright (c) 2011 University of Bremen, TZI
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
 * - Neither the name of the copyright holders nor the names of
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
 */
#include <lib6lowpan/ip.h>
typedef uint8_t method_t;

interface CoAPClient {
  /**
   * Sends a new CoAP request.
   *
   * The CoAP library handles PDU retransmissions automatically.
   * If/when a response is received, @c request_done will be called.
   * Only a single CoAP request can be handled at a time.
   *
   * @param dest Address of CoAP server to send the request to.
   * @param method CoAP method type (COAP_REQUEST_GET, COAP_REQUEST_PUT).
   * @param optlist All CoAP options to include, ordered correctly.
   * @param len Payload length, if the request will have a payload.
   * @param data Payload data. May be NULL if len is zero.
   * @returns SUCCESS if the request is sent.
   */
  command error_t request(struct sockaddr_in6 *dest, method_t method, coap_list_t *optlist, uint16_t len, void *data);

  /**
   * Similar to @c request, but can handle large payloads in the request via
   * the CoAP block mechanism.
   *
   * Payload data is requested as-needed via the @c streamed_next_block event.
   *
   * Not yet implemented.
   *
   * TODO: Implement!
   *
   * @param dest Address of CoAP server to send the request to.
   * @param method CoAP method type (COAP_REQUEST_GET, COAP_REQUEST_PUT).
   * @param optlist All CoAP options to include, ordered correctly.
   * @returns SUCCESS if the request is sent.
   */
  command error_t streamed_request(struct sockaddr_in6 *dest, method_t method, coap_list_t *optlist);

  /**
   * Called in response to a @c streamed_request to obtain payload data.
   *
   * @param blockno The payload block number.
   * @param len On entry set to the desired payload block length. When the end
   *   of the payload data is reached, @c len must be set to the length of the
   *   final block. Returning less payload data than requested is not permitted
   *   except for the final block.
   * @param data Receives the pointer to the next block of payload data.
   * @returns SUCCESS if the payload data block could be provided.
   */
  event error_t streamed_next_block(uint16_t blockno, uint16_t *len, void **data);


  /**
   * Called when a response is received.
   *
   * TODO: Implement support for CoAP block responses.
   *
   * @param code The CoAP response code (in 3.5 packed format).
   * @param mediatype Response payload media type, if applicable.
   * @param len The length of any payload data, or zero if no response payload.
   * @param data Response payload data, if any.
   * @param more If set, the response is using block transfer and there are
   *   further data blocks expected. The final block does not have this flag
   *   set.
   */
  event void request_done(uint8_t code, uint8_t mediatype, uint16_t len, void *data, bool more);
}
