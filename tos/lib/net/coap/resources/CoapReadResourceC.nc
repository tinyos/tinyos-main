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

generic configuration CoapReadResourceC(typedef val_t, uint8_t uri_key) {
    provides interface CoapResource;
    uses interface Read<val_t>;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    uses interface LocalIeeeEui64;
#endif
} implementation {
    components LedsC;
    components new TimerMilliC() as PreAckTimer;
    components new CoapReadResourceP(val_t, uri_key) as CoapReadResourceP;

    CoapResource = CoapReadResourceP;

    CoapReadResourceP.Leds -> LedsC;
    CoapReadResourceP.PreAckTimer -> PreAckTimer;
    CoapReadResourceP.Read = Read;
#if defined (COAP_CONTENT_TYPE_JSON) || defined (COAP_CONTENT_TYPE_XML)
    CoapReadResourceP.LocalIeeeEui64 = LocalIeeeEui64;
#endif
}
