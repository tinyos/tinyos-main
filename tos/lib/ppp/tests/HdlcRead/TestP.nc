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
#include "HdlcFraming.h"
module TestP {
  uses {
    interface Boot;
    interface MultiLed;
    interface StdControl as HdlcControl;
    interface HdlcFraming;
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
  }
  
} implementation {

#ifndef ACCOMP
#define ACCOMP 0
#endif

  const uint8_t* rx_buffer;
  int frame_length;

  task void showFrame ()
  {
    const uint8_t* fp = rx_buffer;
    const uint8_t* fe = fp + frame_length;

    if (fp) {
      printf("Frame of %d chars:", fe - fp);
      while (fp < fe) {
        printf(" %02x", *fp++);
      }
      printf("\r\n");
      call HdlcFraming.releaseReceivedFrame(rx_buffer);
      rx_buffer = 0;
    } else {
      printf("ERROR: showFrame() with no frame available\r\n");
    }
  }

  event void Boot.booted() {
    error_t rc;
    HdlcFramingOptions_t options;
    memset(&options, 0, sizeof(options));
#if ACCOMP
    options.txSuppressAddressControl = options.rxSuppressAddressControl = 1;
#endif;
    rc = call HdlcFramingOptions.set(&options);
    if (SUCCESS != rc) {
      printf("*** ERROR configuring HDLC options\r\n");
      return;
    }
    options = call HdlcFramingOptions.get();
    printf("\r\n\r\n! compress_ac %d\r\n", (options.txSuppressAddressControl << 1) | options.rxSuppressAddressControl);
    printf("# Boot configuration ready\r\n");
    rc = call HdlcControl.start();
    if (SUCCESS != rc) {
      printf("# HDLC start got %d\r\n", rc);
    }
  }

  event void HdlcFraming.sendDone (const uint8_t* data, unsigned int len, error_t err) { }

  event void HdlcFraming.receivedFrame (const uint8_t* data, unsigned int len)
  {
    rx_buffer = data;
    frame_length = len;
    post showFrame();
  }

  async event void HdlcFraming.receivedDelimiter () { }
  async event void HdlcFraming.receptionError (HdlcError_e error)
  {
    call MultiLed.set(0x10 + error);
  }
}
