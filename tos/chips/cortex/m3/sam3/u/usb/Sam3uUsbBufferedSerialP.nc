/*
 * Copyright (c) 2010 CSIRO Australia
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

/**
 * High Speed USB to Serial implementation
 *
 * @author Kevin Klues
 */

#include <sam3uudphshardware.h>

module Sam3uUsbBufferedSerialP {
  provides {
    interface StdControl;
    interface UartByte;
    interface UartStream;
  } 
  uses {
    interface StdControl as SubStdControl;
    interface UartStream as SubUartStream;
  }
}
implementation {
  #define WBUF_SIZE 256 
  #define RBUF_SIZE 256
  typedef struct {
    uint8_t buf[WBUF_SIZE];
    uint8_t idx;
    bool free;
  } wbuf_t;

  wbuf_t wbufs[2];
  uint8_t cwbuf;
  wbuf_t *pwbuf;
  uint8_t rbuf[RBUF_SIZE];

  command error_t StdControl.start() {
    error_t e = call SubStdControl.start();
    atomic {
      cwbuf = 0;
      pwbuf = NULL;
      wbufs[0].idx = 0;
      wbufs[1].idx = 0;
      wbufs[1].free = TRUE;
      wbufs[1].free = TRUE;
    }
    while(call SubUartStream.receive(rbuf, RBUF_SIZE) != SUCCESS);
    return e;
  }

  command error_t StdControl.stop() {
    return call SubStdControl.stop();
  }

  async command error_t UartByte.send( uint8_t byte ) {
    return FAIL;
  }

  /*
   * Check to see if space is available for another transmit byte to go out.
   */
  async command bool UartByte.sendAvail() {
    return FALSE;
  }


  async command error_t UartByte.receive( uint8_t* byte, uint8_t timeout ) {
    return FAIL;
  }

  /*
   * Check to see if another Rx byte is available.
   */
  async command bool UartByte.receiveAvail() {
    return FALSE;
  }


  // Take a look in HdlcTranslateC to understand the logic here
  // on determining whether this is the last byte or not
  bool lastByte(uint8_t byte) {
    static bool seen_delimiter = FALSE;
    static uint8_t esc_count = 0;

    if(!seen_delimiter && (byte == HDLC_FLAG_BYTE))
      seen_delimiter = TRUE;
    else if(seen_delimiter 
            && (byte == HDLC_FLAG_BYTE) 
            && ((esc_count % 2) == 0)) {
      seen_delimiter = FALSE;
      esc_count = 0;
      return TRUE;
    }

    if(byte == HDLC_CTLESC_BYTE)
      esc_count++;
    else 
      esc_count = 0;

    return FALSE;
  }

  task void sendTask() {
    wbuf_t *pwbuf_temp;
    atomic pwbuf_temp = pwbuf;
    while(call SubUartStream.send(pwbuf_temp->buf, pwbuf_temp->idx) != SUCCESS);
  }

  task void byteBufferedTask() {
    // I know HdlcTranslateC is not checking the value of buf, so just pass NULL 
    signal UartStream.sendDone(NULL, 1, SUCCESS);
  }

  async command error_t UartStream.send( uint8_t* buf, uint16_t len ) {
    // Assumes only called with one byte at a time!!
    // This is the behaviour of the current serial stack...
    atomic {
      wbufs[cwbuf].buf[wbufs[cwbuf].idx++] = buf[0]; 
      if(!lastByte(buf[0])) {
        // Post a task to signal sendDone back to HdlcTranslateC
        // Should be OK because of the way send() is always a tail call in this
        // component, and these are async functions.
        post byteBufferedTask();
      }
      else {
        wbufs[cwbuf].free = FALSE;
 
        if(!pwbuf) {
          pwbuf = &(wbufs[cwbuf]);
          cwbuf = !cwbuf;
          post byteBufferedTask();
          post sendTask();
        }
      }
    }
    return SUCCESS;
  }

  async event void SubUartStream.sendDone( uint8_t* buf, uint16_t len, error_t error ) {
    atomic {
      pwbuf->idx = 0;
      pwbuf->free = TRUE;

      if(!wbufs[cwbuf].free) {
        pwbuf = &(wbufs[cwbuf]);
        cwbuf = !cwbuf;
        post byteBufferedTask();
        post sendTask();
      }
      else {
        pwbuf = NULL;
      }
    }
  }
  
  async command error_t UartStream.receive( uint8_t* buf, uint16_t len ) {
    return call SubUartStream.receive(buf, len);
  }

  async event void SubUartStream.receiveDone( uint8_t *buf, uint16_t len, error_t error ) {
    while(call SubUartStream.receive(rbuf, RBUF_SIZE) != SUCCESS);
    signal UartStream.receiveDone(buf, len, error);
  }

  async event void SubUartStream.receivedByte( uint8_t byte ) {
    signal UartStream.receivedByte(byte);
  }

  async command error_t UartStream.enableReceiveInterrupt() {
    return call SubUartStream.enableReceiveInterrupt();
  }

  async command error_t UartStream.disableReceiveInterrupt() {
    return call SubUartStream.disableReceiveInterrupt();
  }
}

