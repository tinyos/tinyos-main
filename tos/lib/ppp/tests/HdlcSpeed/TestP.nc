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
#include "config.h"
module TestP {
  uses {
    interface Boot;
    interface Led as SendLed;
    interface Led as ReceiveLed;
    interface Led as ErrorLed;
    interface HdlcFraming;
    interface StdControl as HdlcControl;
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
    interface LocalTime<TMicro> as LocalTimeMicro;
#if PLATFORM_SURF
    interface Msp430UsciError;
#endif /* PLATFORM_SURF */
#if WITH_DISPLAYCODE
    interface DisplayCode as DisplayCodeHdlc;
    interface DisplayCode as DisplayCodeHdlcCount;
#endif /* WITH_DISPLAYCODE */
  }
  
} implementation {

  typedef nx_struct payload_t {
    nx_uint16_t tx_id;
    nx_uint16_t rx_length;
    nx_uint16_t rx_id;
    nx_uint32_t rx_duration_us;
    nx_uint32_t tx_duration_us;
    nx_uint32_t hdlc_errors;
    nx_uint16_t usci_error_count;
    nx_uint16_t usci_error_bits;
  } payload_t;

  uint8_t tx_frame[FRAME_SIZE];
  unsigned int rx_length;
  payload_t* tx_payload = (payload_t*)tx_frame;
  unsigned int tx_id;
  unsigned int rx_last_id;
  uint32_t hdlc_errors;
  uint16_t hdlc_error_count;
  uint16_t usci_error_count;
  uint16_t usci_error_bits;
  uint32_t rx_start_us;
  uint32_t rx_duration_us;
  uint32_t tx_start_us;
  uint32_t tx_duration_us;
  bool send_on_rx;
  
  void startReceive ()
  {
    atomic {
      rx_start_us = call LocalTimeMicro.get();
    }
  }

  task void startSend ()
  {
    error_t rc;

    if (tx_id >= REPETITIONS) {
      return;
    }
    atomic {
      tx_payload->tx_id = ++tx_id;
      tx_payload->rx_length = rx_length;
      tx_payload->rx_id = rx_last_id;
      tx_payload->rx_duration_us = rx_duration_us;
      tx_payload->tx_duration_us = tx_duration_us;
      tx_payload->hdlc_errors = hdlc_errors;
      tx_payload->usci_error_count = usci_error_count;
      tx_payload->usci_error_bits = usci_error_bits;
      hdlc_errors = 0;
      usci_error_bits = 0;
    }
    tx_start_us = call LocalTimeMicro.get();
    rc = call HdlcFraming.sendFrame(tx_frame, sizeof(tx_frame), FALSE);
    if (SUCCESS == rc) {
      call SendLed.on();
    }
  }

  event void Boot.booted() {
    error_t rc;
    HdlcFramingOptions_t options;
//    options = call HdlcFramingOptions.get();
    memset(&options, 0, sizeof(options));
#if ACCOMP
    options.txSuppressAddressControl = options.rxSuppressAddressControl = 1;
#endif;
    rc = call HdlcFramingOptions.set(&options);
    if (SUCCESS != rc) {
      printf("*** ERROR: Attempt to configure options failed\r\n");
      return;
    }
#if WITH_DISPLAYCODE
    call DisplayCodeHdlc.setValueWidth(1);
    call DisplayCodeHdlcCount.setValueWidth(2);
#endif /* WITH_DISPLAYCODE */

    options = call HdlcFramingOptions.get();
    printf("\r\n\r\n! compress_ac %d\r\n", (options.txSuppressAddressControl << 1) | options.rxSuppressAddressControl);
    printf("! frame_size %d\r\n", FRAME_SIZE);
    printf("! repetitions %d\r\n", REPETITIONS);
    printf("! full_duplex %d\r\n", FULL_DUPLEX);
    call HdlcControl.start();
    printf("# Boot configuration ready\r\n");
    atomic {
      send_on_rx = TRUE;
    }
    startReceive();
  }

  async event void HdlcFraming.receivedDelimiter () { }

  async event void HdlcFraming.receptionError (HdlcError_e error)
  {
    atomic {
      hdlc_errors = error; // (hdlc_errors * 10) | error;
      ++hdlc_error_count;
    }
#if WITH_DISPLAYCODE
    call DisplayCodeHdlc.setValue(error);
    call DisplayCodeHdlc.enable(TRUE);
    call DisplayCodeHdlcCount.setValue(hdlc_error_count);
    call DisplayCodeHdlcCount.enable(TRUE);
#else /* WITH_DISPLAYCODE */
    call ErrorLed.on();
#endif /* WITH_DISPLAYCODE */
  }

  event void HdlcFraming.sendDone (const uint8_t* data,
                                   unsigned int len,
                                   error_t err)
  {
    uint32_t now = call LocalTimeMicro.get();
    tx_duration_us = now - tx_start_us;
    call SendLed.off();
#if FULL_DUPLEX
    post startSend();
#endif
  }

  event void HdlcFraming.receivedFrame (const uint8_t* data,
                                        unsigned int len)
  {
    uint32_t now = call LocalTimeMicro.get();
    call ReceiveLed.toggle();
    rx_duration_us = now - rx_start_us;
    rx_length = len;
    rx_last_id = ((payload_t*)data)->tx_id;
    call HdlcFraming.releaseReceivedFrame(data);
    startReceive();
    if (send_on_rx) {
      post startSend();
#if FULL_DUPLEX
      send_on_rx = FALSE;
#endif
    }
  }

#if PLATFORM_SURF
  async event void Msp430UsciError.condition (unsigned int errors)
  {
    atomic {
      ++usci_error_count;
      usci_error_bits |= errors;
    }
  }
#endif /* PLATFORM_SURF */
}

