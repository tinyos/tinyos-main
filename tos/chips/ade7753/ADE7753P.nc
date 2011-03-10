/*
 * Copyright (c) 2011 The Regents of the University  of California.
 * All rights reserved."
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

#include <ADE7753.h>

module ADE7753P
{
  provides {
    interface Init;
    interface SplitControl;
    interface ADE7753;
  }

  uses {
    interface Resource;

    interface SpiPacket;
    interface GeneralIO as SPIFRM;
    interface Leds;
  }
}

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_GETREG,
    STATE_SETREG,
    STATE_ERROR
  };

  uint8_t mSPIRxBuf[4],mSPITxBuf[4];
  uint8_t mSPITxLen;
  uint8_t mSPIRxLen;

  //  bool lock;
  uint8_t mState;
  bool misInited = FALSE;
  norace error_t mSSError;


  task void StartDone() {
    atomic mState = STATE_IDLE;
    signal SplitControl.startDone(SUCCESS);
    return;
  }

  task void StopDone() {
    signal SplitControl.stopDone(mSSError);
    return;
  }

  command error_t Init.init() {
    atomic {
      if (!misInited) {
        misInited = TRUE;
        mState = STATE_STOPPED;
      }
      // Control CS pin manually
      call SPIFRM.makeOutput();
      call SPIFRM.set();
    }
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
        mState = STATE_IDLE;
      }
      else {
        error = EBUSY;
      }
    }
    if (error) 
      return error;

    atomic mState = STATE_IDLE;
    call SPIFRM.set();

    post StartDone();
    return error;
  }

  command error_t SplitControl.stop() {
    error_t error = SUCCESS;

    //	atomic lock = FALSE;
    atomic {
      if (mState == STATE_IDLE) {
        // mState = STATE_STOPPING;
        mState = STATE_STOPPED;
      }
      else { 
        error = EBUSY;
      }
    }
    if (error)
      return error;

    atomic mState = STATE_STOPPED;	
    call SPIFRM.set();

    post StopDone();
    return error;
  }


  event void Resource.granted() {
    atomic switch(mState) {
      case STATE_GETREG:
        // call Leds.led0Toggle();
        call SPIFRM.clr(); // CS LOW
        if (call SpiPacket.send(mSPITxBuf,mSPIRxBuf,mSPIRxLen) == FAIL)
          call Resource.request();
        break;
      case STATE_SETREG:
        //		  call Leds.led0On();
        call SPIFRM.clr(); // CS LOW
        if (call SpiPacket.send(mSPITxBuf,mSPIRxBuf,mSPITxLen) == FAIL)
          call Resource.request();
        break;
      default:
        call Resource.release();
    }
  }

  // Here I'm forcing 24 bit receive data
  async command error_t ADE7753.getReg(uint8_t regAddr, uint8_t len) {
    error_t error = SUCCESS;

    atomic {
      if (mState != STATE_IDLE) {
        return FAIL;
      } else {
        mState = STATE_GETREG;
      }
    }

    mSPITxBuf[0] = regAddr;
    mSPITxBuf[1] = 0;
    mSPITxBuf[2] = 0;
    mSPITxBuf[3] = 0;

    mSPIRxBuf[0] = 0;
    mSPIRxBuf[1] = 0;
    mSPIRxBuf[2] = 0;
    mSPIRxBuf[3] = 0;

    mSPIRxLen = len;

    call Resource.request();

    return error;

  }


  // here I'm forcing 24bit of val during a write
  async command error_t ADE7753.setReg(uint8_t regAddr, uint8_t len, uint32_t val) {
    error_t error = SUCCESS;

    atomic {
      if (mState != STATE_IDLE) {
        return FAIL;
      } else {
        mState = STATE_SETREG;
      }
    }

    // call Leds.led0On();

    atomic
    {
      mSPITxBuf[0] = regAddr | (1 << 7); // set the WRITE bit

      switch (len) {
        case 2:
          mSPITxBuf[1] = (uint8_t) val;
          break;
        case 3:
          mSPITxBuf[1] = (uint8_t) (val>>8);
          mSPITxBuf[2] = (uint8_t) val;
          break;
        case 4:
          mSPITxBuf[1] = (uint8_t) (val>>16);
          mSPITxBuf[2] = (uint8_t) (val>>8);
          mSPITxBuf[3] = (uint8_t) val;
          break;
      }

      mSPITxLen = len;
    }

    //	call Leds.led0On();

    call Resource.request();
    return error;
  }

  async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t spi_error ) {

    uint32_t val;
    error_t error = spi_error;

    call SPIFRM.set(); // CS HIGH

    atomic {
      switch (mState) {
        case STATE_GETREG:
          mState = STATE_IDLE;
          // repack
          switch (len) {
            case 2:
              val = rxBuf[1];
              break;
            case 3:
              val = ((uint32_t)rxBuf[1])<<8 | rxBuf[2];
              break;
            case 4:
              val = ((uint32_t)rxBuf[1])<<16 | ((uint32_t)rxBuf[2])<<8 | rxBuf[3];
              break;
            default:
              val = 0xF0F0F0F0;
              break;
          }
          signal ADE7753.getRegDone(error, (txBuf[0] & 0x7F), val, len);
          break;
        case STATE_SETREG:

          //		call Leds.led1Toggle();

          mState = STATE_IDLE;

          // repack
          switch (len) {
            case 2:
              val = txBuf[1];
              break;
            case 3:
              val = ((uint32_t)txBuf[1])<<8 | txBuf[2];
              break;
            case 4:
              val = ((uint32_t)txBuf[1])<<16 | ((uint32_t)txBuf[2])<<8 | txBuf[3];
              break;
            default:
              val = 0xF0F0F0F0;
              break;
          }		
          signal ADE7753.setRegDone(error, (txBuf[0] & 0x7F), val, len);
          break;
        default:
          mState = STATE_IDLE;
          break;
      }
    }
    call Resource.release();

    return;
  }

  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }

}
