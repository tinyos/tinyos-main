/* $Id: HalPXA27xI2CMasterP.nc,v 1.4 2006-12-12 18:23:12 vlahan Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * This Hal module implements the TinyOS 2.0 I2CPacket interface over
 * the PXA27x I2C Hpl
 *
 * @author Phil Buonadonna
 */

#include <I2C.h>

generic module HalPXA27xI2CMasterP(bool fast_mode)
{
  provides interface Init;
  provides interface I2CPacket<TI2CBasicAddr>;

  uses interface HplPXA27xI2C as I2C;

  uses interface HplPXA27xGPIOPin as I2CSCL;
  uses interface HplPXA27xGPIOPin as I2CSDA;

}

implementation
{
  // These states don't necessarily reflect the state of the I2C bus, rather the state of this
  // module WRT an operation.  I.E. the module might be in STATE_IDLE, but the I2C bus still
  // held by the master for a continued read.
  enum {
    I2C_STATE_IDLE,
    I2C_STATE_READSTART,
    I2C_STATE_READ,
    I2C_STATE_READEND,
    I2C_STATE_WRITE,
    I2C_STATE_WRITEEND,
    I2C_STATE_ERROR
  };

  uint8_t mI2CState;
  uint16_t mCurTargetAddr;
  uint8_t *mCurBuf, mCurBufLen, mCurBufIndex;
  i2c_flags_t mCurFlags;
  uint32_t mBaseICRFlags;

  static void readNextByte() {
    if (mCurBufIndex >= (mCurBufLen - 1)) {
      atomic { mI2CState = I2C_STATE_READEND; }
      if (mCurFlags & I2C_STOP) {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_ACKNAK | ICR_TB | ICR_STOP));
      }
      else if (mCurFlags & I2C_ACK_END) {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_TB));
      }
      else {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_ACKNAK | ICR_TB));
      }
    }
    else {
      atomic { mI2CState = I2C_STATE_READ; }
      call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_DRFIE | ICR_TB));
    }
    return;
  }

  static void writeNextByte() {
    if (mCurBufIndex >= mCurBufLen) {
      atomic { mI2CState = I2C_STATE_WRITEEND; }
      
      if (mCurFlags & I2C_STOP) {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_TB | ICR_ITEIE | ICR_STOP));
      }
      
      else {
	call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_ITEIE | ICR_TB));
      }
      
    }
    else {
      call I2C.setICR((mBaseICRFlags) | (ICR_ALDIE | ICR_ITEIE |ICR_TB));
    }
    return;
  }
  
  static error_t startI2CTransact(uint8_t nextState, uint16_t addr, uint8_t length, uint8_t *data, 
			   i2c_flags_t flags, bool bRnW) {
    error_t error = SUCCESS;
    uint8_t tmpAddr;

    if ((data == NULL) || (length == 0)) {
      return EINVAL;
    }

    atomic {
      if (mI2CState == I2C_STATE_IDLE) {
	mI2CState = nextState;
	mCurTargetAddr = addr;
	mCurBuf = data;
	mCurBufLen = length;
	mCurBufIndex = 0;
	mCurFlags = flags;
      }
      else {
	error = EBUSY;
      }
    }
    if (error) {
      return error;
    }

    if (flags & I2C_START) {

      tmpAddr = (bRnW) ? 0x1 : 0x0;
      tmpAddr |= ((addr << 1) & 0xFE);
      call I2C.setIDBR(tmpAddr);
      call I2C.setICR( mBaseICRFlags | ICR_ITEIE | ICR_TB | ICR_START);
    }
    else if (bRnW) {
      atomic {
	readNextByte();
      }
    }
    else {
      atomic {
	writeNextByte();
      }
    }
    return error;
  }


  task void handleReadError() {
    call I2C.setISAR(0x7F0);
    call I2C.setICR(mBaseICRFlags | ICR_MA);
    call I2C.setICR(ICR_UR);
    call I2C.setICR(mBaseICRFlags);
    atomic {
      mI2CState = I2C_STATE_IDLE;
      signal I2CPacket.readDone(FAIL,mCurTargetAddr,mCurBufLen,mCurBuf);
    }
    return;
  }
    
  task void handleWriteError() {
    call I2C.setISAR(0x7F0);
    call I2C.setICR(mBaseICRFlags | ICR_MA);
    call I2C.setICR(ICR_UR);
    call I2C.setICR(mBaseICRFlags);
    atomic {
      mI2CState = I2C_STATE_IDLE;
      signal I2CPacket.writeDone(FAIL,mCurTargetAddr,mCurBufLen,mCurBuf);
    }
    return;
  }

  command error_t Init.init() {
    atomic {
      mBaseICRFlags = (fast_mode) ? (ICR_FM | ICR_BEIE | ICR_IUE | ICR_SCLE) : (ICR_BEIE | ICR_IUE | ICR_SCLE);

      call I2CSCL.setGAFRpin(I2C_SCL_ALTFN);
      call I2CSCL.setGPDRbit(TRUE);
      call I2CSDA.setGAFRpin(I2C_SDA_ALTFN);
      call I2CSDA.setGPDRbit(TRUE);

      mI2CState = I2C_STATE_IDLE;
      call I2C.setISAR(0);
      call I2C.setICR(mBaseICRFlags | ICR_ITEIE | ICR_DRFIE);
    }    
    return SUCCESS;
  }

  async command error_t I2CPacket.read(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data) {
    error_t error = SUCCESS;

    if ((flags & I2C_ACK_END) && (flags & I2C_STOP)) {
      error = EINVAL;
      return error;
    }

    if (flags & I2C_START) {
      error = startI2CTransact(I2C_STATE_READSTART,addr,length,data,flags,TRUE);
    }
    else {
      error = startI2CTransact(I2C_STATE_READ,addr,length,data,flags,TRUE);
    }
    
    return error;
  }

  async command error_t I2CPacket.write(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data) {
    error_t error = SUCCESS;

    error = startI2CTransact(I2C_STATE_WRITE,addr,length,data,flags,FALSE);

    return error;
  }

  async event void I2C.interruptI2C() {
    uint32_t valISR;

    // PXA27x Devel Guide is wrong.  You have to write to the ISR to clear the bits.
    valISR = call I2C.getISR();
    call I2C.setISR(ISR_ITE | ISR_IRF);

    // turn off DRFIE and ITEIE
    //call I2C.setICR((call I2C.getICR()) & ~(ICR_DRFIE | ICR_ITEIE));
    //call I2C.setICR(mBaseICRFlags);

    switch (mI2CState) {
    case I2C_STATE_IDLE:
      // Should never get here. Reset all pending interrupts.
      break;

    case I2C_STATE_READSTART:
      if (valISR & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleReadError();
	break;
      }
      readNextByte();
      break;

    case I2C_STATE_READ:
      if (valISR & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleReadError();
	break;
      }
      mCurBuf[mCurBufIndex] = call I2C.getIDBR();
      mCurBufIndex++;
      readNextByte();
      break;

    case I2C_STATE_READEND:
      if (valISR & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleReadError();
	break;
      }
      mCurBuf[mCurBufIndex] = call I2C.getIDBR();
      mI2CState = I2C_STATE_IDLE;
      signal I2CPacket.readDone(SUCCESS,mCurTargetAddr,mCurBufLen,mCurBuf);
      break;

    case I2C_STATE_WRITE:
      if (valISR & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleWriteError();
	break;
      }
      call I2C.setIDBR(mCurBuf[mCurBufIndex]);
      mCurBufIndex++;
      writeNextByte();

      break;

    case I2C_STATE_WRITEEND:
      if (valISR & (ISR_BED | ISR_ALD)) {
	mI2CState = I2C_STATE_ERROR;
	post handleWriteError();
	break;
      }
      mI2CState= I2C_STATE_IDLE;
      //call I2C.setICR(call I2C.getICR() & ~I2C_STOP);
      call I2C.setICR(mBaseICRFlags);
      signal I2CPacket.writeDone(SUCCESS,mCurTargetAddr,mCurBufLen,mCurBuf);
      break;

    default:
      break;
    }

      
    return;
  }

  default async event void I2CPacket.readDone(error_t error, uint16_t addr, 
					     uint8_t length, uint8_t* data) {
    return;
  }

  default async event void I2CPacket.writeDone(error_t error, uint16_t addr, 
						     uint8_t length, uint8_t* data) { 
    return;
  }

  async event void I2CSDA.interruptGPIOPin() {}
  async event void I2CSCL.interruptGPIOPin() {}
}
