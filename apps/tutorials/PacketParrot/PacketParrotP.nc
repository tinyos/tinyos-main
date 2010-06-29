/*                                                                      tab:2
 *
 * Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
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
 *
 */

/**
 * Implementation of the <code>PacketParrot</code> application.
 *
 * @author Prabal Dutta
 * @date   Apr 6, 2007
 */
module PacketParrotP {
  uses {
    interface Boot;
    interface Leds;
    interface Packet;
    interface Send;
    interface Receive;
    interface SplitControl as AMControl;
    interface LogRead;
    interface LogWrite;
    interface Timer<TMilli> as Timer0;
  }
}
implementation {

  enum {
    INTER_PACKET_INTERVAL = 25
  };

  typedef nx_struct logentry_t {
    nx_uint8_t len;
    message_t msg;
  } logentry_t;

  bool m_busy = TRUE;
  logentry_t m_entry;

  event void Boot.booted() {
    call AMControl.start();
  }


  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (call LogRead.read(&m_entry, sizeof(logentry_t)) != SUCCESS) {
	// Handle error.
      }
    }
    else {
      call AMControl.start();
    }
  }


  event void AMControl.stopDone(error_t err) {
  }


  event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
    if ( (len == sizeof(logentry_t)) && (buf == &m_entry) ) {
      call Send.send(&m_entry.msg, m_entry.len);
      call Leds.led1On();
    }
    else {
      if (call LogWrite.erase() != SUCCESS) {
	// Handle error.
      }
      call Leds.led0On();
    }
  }


  event void Send.sendDone(message_t* msg, error_t err) {
    call Leds.led1Off();
    if ( (err == SUCCESS) && (msg == &m_entry.msg) ) {
      call Packet.clear(&m_entry.msg);
      if (call LogRead.read(&m_entry, sizeof(logentry_t)) != SUCCESS) {
	// Handle error.
      }
    }
    else {
      call Timer0.startOneShot(INTER_PACKET_INTERVAL);
    }
  }


  event void Timer0.fired() {
    call Send.send(&m_entry.msg, m_entry.len);
  }


  event void LogWrite.eraseDone(error_t err) {
    if (err == SUCCESS) {
      m_busy = FALSE;
    }
    else {
      // Handle error.
    }
    call Leds.led0Off();
  }


  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    call Leds.led2On();
    if (!m_busy) {
      m_busy = TRUE;
      m_entry.len = len;
      m_entry.msg = *msg;
      if (call LogWrite.append(&m_entry, sizeof(logentry_t)) != SUCCESS) {
	m_busy = FALSE;
      }
    }
    return msg;
  }

  event void LogWrite.appendDone(void* buf, storage_len_t len, 
                                 bool recordsLost, error_t err) {
    m_busy = FALSE;
    call Leds.led2Off();
  }

  event void LogRead.seekDone(error_t err) {
  }

  event void LogWrite.syncDone(error_t err) {
  }

}
