//$Id: HdlcTranslateC.nc,v 1.2 2006-07-12 17:02:28 scipio Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * This is an implementation of HDLC serial encoding, supporting framing
 * through frame delimiter bytes and escape bytes.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include "Serial.h"

module HdlcTranslateC {
  provides interface SerialFrameComm;
  uses {
    interface SerialByteComm;
    interface Leds;
  }
}

implementation {
  typedef struct {
    uint8_t sendEscape:1;
    uint8_t receiveEscape:1;
  } HdlcState;
  
  //norace uint8_t debugCnt = 0;
  norace HdlcState state = {0,0};
  norace uint8_t txTemp;

  
  // TODO: add reset for when SerialM goes no-sync.
  async command void SerialFrameComm.resetReceive(){
    state.receiveEscape = 0;
  }
  async command void SerialFrameComm.resetSend(){
    state.sendEscape = 0;
  }
  async event void SerialByteComm.get(uint8_t data) {
    //debugCnt++;
    // 7E 41 0E 05 04 03 02 01 00 01 8F 7E
/*     if (debugCnt == 1 && data == 0x7E) call Leds.led0On(); */
/*     if (debugCnt == 2 && data == 0x41) call Leds.led1On(); */
/*     if (debugCnt == 3 && data == 0x0E) call Leds.led2On(); */

    if (data == HDLC_FLAG_BYTE) {
      //call Leds.led1On();
      signal SerialFrameComm.delimiterReceived();
      return;
    }
    else if (data == HDLC_CTLESC_BYTE) {
      //call Leds.led1On();
      state.receiveEscape = 1;
      return;
    }
    else if (state.receiveEscape) {
      //call Leds.led1On();
      state.receiveEscape = 0;
      data = data ^ 0x20;
    }
    signal SerialFrameComm.dataReceived(data);
  }

  async command error_t SerialFrameComm.putDelimiter() {
    state.sendEscape = 0;
    return call SerialByteComm.put(HDLC_FLAG_BYTE);
  }
  
  async command error_t SerialFrameComm.putData(uint8_t data) {
    if (data == HDLC_CTLESC_BYTE || data == HDLC_FLAG_BYTE) {
      state.sendEscape = 1;
      txTemp = data ^ 0x20;
      return call SerialByteComm.put(HDLC_CTLESC_BYTE);
    }
    else {
      return call SerialByteComm.put(data);
    }
  }

  async event void SerialByteComm.putDone() {
    if (state.sendEscape) {
      state.sendEscape = 0;
      call SerialByteComm.put(txTemp);
    }
    else {
      signal SerialFrameComm.putDone();
    }
  }
}
