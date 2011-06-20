/* Copyright (c) 2011 University of California, Berkeley
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
/*
 * Improved DMA UART implementation for MSP-base platforms to fix some
 * of the timing issues.  Based on my earlier implementation, but
 * moved to Peter Bigot's new layer so we can coexist with other
 * serial port users.
 * 
 * Instead of needing to service each UART interrupt as they occur, we
 * set up a continuous DMA transfer into a ring buffer; and an alarm
 * which periodically checks the progress of the transfer and delivers
 * data if new bytes have come in.  This results in significantly
 * looser timing requirements.
 * 
 * The size of the buffer controls how much freedom you have, timing
 * wise; you can set this at compile time with
 * PLATFORM_SERIAL_RX_BUFFER_SIZE
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

#include <Timer.h>
#include <Msp430Dma.h>

module PlatformHdlcUartP {
  provides {
    interface StdControl;
    interface HdlcUart;
    interface ResourceConfigure;
  }
  uses {
    interface Resource as UsartResource;
    interface Msp430UartConfigure;
    interface HplMsp430Usart as Usart;
    interface HplMsp430UsartInterrupts as UsartInterrupts;

    interface Msp430DmaChannel as DmaChannel;

    interface Alarm<T32khz, uint16_t> as RxAbort;

    interface Leds;
  }
} implementation {  
  norace uint16_t m_tx_len;
  norace uint8_t * COUNT_NOK(m_tx_len) m_tx_buf, * COUNT_NOK(sizeof(__rx_buf)) m_rx_buf;
  norace uint16_t m_tx_pos;
  norace uint8_t m_byte_time;
#ifndef PLATFORM_SERIAL_RX_BUFFER_SIZE
  /* at 115200 baud, this is about 9ms of buffer 
   *
   * therefore, that is the longest we can get delayed by other
   * tasks without dropping * bytes.
   */
#define PLATFORM_SERIAL_RX_BUFFER_SIZE 64
#endif
  uint8_t __rx_buf[PLATFORM_SERIAL_RX_BUFFER_SIZE];
  bool m_rx_enabled;
  norace uint8_t *m_rx_delivery_start, *m_rx_delivery_stop;

  enum {
    // this is essentially how often the alarm fires, as a fraction of
    // the buffer.  For instance, at the default of three, the
    // delivery check should run every time the buffer would have
    // filled by a third if we were receiving the whole time.
    BUFFER_TIMEOUT_BYTES = 8,
  };

  command error_t StdControl.start() {
    call Leds.led1Toggle();
    return call UsartResource.request();
  }

  command error_t StdControl.stop() {
    call UsartResource.release();
    call RxAbort.stop();
    return SUCCESS;
  }

  async command void ResourceConfigure.configure() {
    msp430_uart_union_config_t* config = call Msp430UartConfigure.getConfig();
    call Leds.led0On();
    m_byte_time = (config->uartConfig.ubr / 4); // SDH : assume 4MHZ...
    call Usart.setModeUart(config);
    call Usart.enableIntr();
  }

  async command void ResourceConfigure.unconfigure() {
    call RxAbort.stop();
    call DmaChannel.stopTransfer();

    call Usart.resetUsart(TRUE);
    call Usart.disableIntr();
    call Usart.disableUart();

    /* leave the usart in reset */
    //call Usart.resetUsart(FALSE); // this shouldn't be called.
  }

  /*
   * Receive side
   *
   * Incoming bytes are placed into the buffer by the DMA processor,
   * and delivered asynchronously by the receive task, which is
   * started from an alarm, and from the dma interrupt if present.
   * There is still the possiblity for buffer underruns if the receive
   * handler delays too long or the alarm cannot run.
   */
  task void deliverTask() {
    /* deliver to the stop point, or the end of the buffer */
    while (m_rx_delivery_start != m_rx_delivery_stop) {
      signal HdlcUart.receivedByte(*(m_rx_delivery_start++));
      if (m_rx_delivery_start == m_rx_buf + sizeof(__rx_buf))
        m_rx_delivery_start = m_rx_buf;
    }
  }

  event void UsartResource.granted() {
    atomic {
      if ( m_rx_buf )
	return;
      m_rx_buf = __rx_buf;

      /* SDH : important : the dma transfer won't occur if the
         interrupt is enabled */
      call Usart.clrRxIntr();
      call Usart.disableRxIntr();
      call DmaChannel.setupTransfer(DMA_REPEATED_SINGLE_TRANSFER,
                                    DMA_TRIGGER_URXIFG1,
                                    DMA_EDGE_SENSITIVE,
                                    (void *)U1RXBUF_,
                                    (void *)m_rx_buf,
                                    sizeof(__rx_buf),
                                    DMA_BYTE,
                                    DMA_BYTE,
                                    DMA_ADDRESS_UNCHANGED,
                                    DMA_ADDRESS_INCREMENTED);
      call DmaChannel.startTransfer();

      /* start the timeout */
      /* this will be fired when the buffer is about a third full so we
         can deliver the first half... */
      m_rx_delivery_stop = m_rx_delivery_start = m_rx_buf;

      call RxAbort.startAt(call RxAbort.getNow(),
                           m_byte_time * BUFFER_TIMEOUT_BYTES);
    }
  }

  async event void UsartInterrupts.rxDone( uint8_t data ) {
    /* if there were a buffer, we would have recieved it on the dma
       channel ... */
    // this should never happen since we're using DMA...
    signal HdlcUart.receivedByte(data);
  }

  async event void RxAbort.fired() { 
    /* time out and deliver  */
    m_rx_delivery_stop = m_rx_buf + sizeof(__rx_buf) - DMA2SZ;
    if (m_rx_delivery_stop != m_rx_delivery_start)
      post deliverTask();

    call RxAbort.startAt(call RxAbort.getNow(), 
                         m_byte_time * BUFFER_TIMEOUT_BYTES);
  }

  async event void DmaChannel.transferDone(error_t success) {  }

  /* 
   * Send side.  no dma here, just send it out.
   *
   * We could do dma in the future, but it ties up another controller,
   * and the timing requirements on the pc side tend to be pretty
   * relaxed so it doesn't really matter if we get delayed while this
   * is going out.
   */
  command error_t HdlcUart.send( uint8_t* buf, uint16_t len ) {
    if ( len == 0 )
      return FAIL;
    else if ( m_tx_buf )
      return EBUSY;
    m_tx_buf = buf;
    m_tx_len = len;
    m_tx_pos = 0;
    call Usart.tx( buf[ m_tx_pos++ ] );
    return SUCCESS;
  }

  async event void UsartInterrupts.txDone() {
    if (m_tx_buf == NULL) return;
    if ( m_tx_pos < m_tx_len ) {
      call Usart.tx( m_tx_buf[ m_tx_pos++ ] );
    }
    else {
      m_tx_buf = NULL;
      signal HdlcUart.sendDone(SUCCESS);
    }
  }
}
