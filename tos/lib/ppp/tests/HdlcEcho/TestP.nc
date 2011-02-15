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

#include <stdio.h>
module TestP {
  uses {
    interface Boot;
    interface MultiLed;
    interface HdlcFraming;
    interface StdControl as HdlcControl;
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
  }
  
} implementation {

#ifndef ACCOMP
#define ACCOMP 0
#endif

#ifndef INHIBIT_ACCOMP
#define INHIBIT_ACCOMP 0
#endif

  uint8_t echo_buffer[1025];
  unsigned int echo_len;

  event void Boot.booted() {
    error_t rc;
    
    HdlcFramingOptions_t options;
    memset(&options, 0, sizeof(options));
#if ACCOMP
    options.txSuppressAddressControl = options.rxSuppressAddressControl = 1;
#endif;
    call HdlcFramingOptions.set(&options);
    options = call HdlcFramingOptions.get();
    printf("\r\n\r\n! compress_ac %d\r\n", (options.txSuppressAddressControl << 1) | options.rxSuppressAddressControl);
    printf("! inhibit_accomp %d\r\n", INHIBIT_ACCOMP);
    printf("# Boot configuration ready\r\n");
    rc = call HdlcControl.start();
    if (SUCCESS != rc) {
      printf("@@@ ERROR: HDLC start got %d\r\n", rc);
    }
  }

  event void HdlcFraming.sendDone (const uint8_t* data,
                                   unsigned int len,
                                   error_t err)
  {
  }
 
  task void sendFrame ()
  {
    call HdlcFraming.sendFrame(echo_buffer, echo_len, INHIBIT_ACCOMP);
  }

  event void HdlcFraming.receivedFrame (const uint8_t* data,
                                        unsigned int len)
  {
    call MultiLed.toggle(0);
    memcpy(echo_buffer+1, data, len);
    call HdlcFraming.releaseReceivedFrame(data);
    echo_buffer[0] = len;
    echo_len = 1 + len;
    post sendFrame();
  }

  async event void HdlcFraming.receivedDelimiter () { }
  async event void HdlcFraming.receptionError (HdlcError_e error) { }
}
