/*                                                                      tab:2
 *
 * "Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
      error_t e;
      do {
        e = call LogRead.read(&m_entry, sizeof(logentry_t));
      } while (e != SUCCESS);
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
      error_t e;
      do {
	e = call LogWrite.erase();
      } while (e != SUCCESS);
      call Leds.led0On();
    }
  }


  event void Send.sendDone(message_t* msg, error_t err) {
    call Leds.led1Off();
    if ( (err == SUCCESS) && (msg == &m_entry.msg) ) {
      error_t e;
      call Packet.clear(&m_entry.msg);
      do {
        e = call LogRead.read(&m_entry, sizeof(logentry_t));
      } while (e != SUCCESS);
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
      if (call LogWrite.append(&m_entry, sizeof(message_t)) != SUCCESS) {
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
