/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.6 $ $Date: 2012-05-25 19:29:48 $
 */

#include <I2C.h>

module Msp430I2CP {
  
  provides interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;

  provides interface Init as I2CInit;

  uses interface HplMsp430I2C as HplI2C;
  uses interface HplMsp430I2CInterrupts as I2CInterrupts;
  
}

implementation {

#ifndef I2CDR_
#define I2CDR I2CDRW
#endif

  MSP430REG_NORACE(I2CIE);
  
  enum {
    OFF = 1,
    IDLE,
    PACKET_WRITE,
    PACKET_READ
  };

  norace uint8_t stateI2C = IDLE;
  uint8_t length;
  uint8_t ptr;
  norace error_t result;
  uint8_t * data;


  command error_t I2CInit.init() {
    atomic stateI2C = IDLE;
    return SUCCESS;
  }

  task void readDone() {
    // variables protected from change by the stateI2C state machine
    error_t _result;
    uint8_t _length;
    uint8_t* _data;
    uint16_t _addr;

    _result = result;
    _length = length;
    _data = data;
    _addr = I2CSA;

    atomic stateI2C = IDLE;
    signal I2CBasicAddr.readDone(_result, _addr, _length, _data);
  }

  task void writeDone() {
    // variables protected from change by the stateI2C state machine
    error_t _result;
    uint8_t _length;
    uint8_t* _data;
    uint16_t _addr;

    _result = result;
    _length = length;
    _data = data;
    _addr = I2CSA;

    // wait for the module to finish its transmission
    // spin only lasts ~4bit times == 4us.
    while (I2CDCTL & I2CBUSY) nop();

    atomic stateI2C = IDLE;
    signal I2CBasicAddr.writeDone(_result, _addr, _length, _data);
  }

  async command error_t I2CBasicAddr.read( i2c_flags_t flags,
					   uint16_t _addr, uint8_t _length, 
					   uint8_t* _data ) {
    uint8_t _state;

    atomic {
      _state = stateI2C;
      if (_state == IDLE) {
	stateI2C = PACKET_READ;
      }
    }

    if (_state == IDLE) {
      // perform register modifications with interrupts disabled
      // to maintain consistent state
      atomic {
	result = FAIL;

	// disable I2C to set the registers
	U0CTL &= ~I2CEN;

	I2CSA = _addr;

	length = _length;
	data = _data;
	ptr = 0;

	U0CTL |= MST;

	I2CNDAT = _length;

	// enable I2C module
	U0CTL |= I2CEN;
	
	// set receive mode
	I2CTCTL &= ~I2CTRX;

	// get an event if the receiver does not ACK
	I2CIE = RXRDYIE | NACKIE;
	I2CIFG = 0;

	// start condition and stop condition need to be sent
	I2CTCTL |= (I2CSTP | I2CSTT);
      }

      return SUCCESS;
    }

    return FAIL;
  }
  
  // handle the interrupt within this component
  void localRxData() {
    uint16_t* _data16 = (uint16_t*)data;

    if (stateI2C != PACKET_READ)
      return;

    // figure out where we are in the transmission
    // should only occur when I2CNDAT > 0
    if (I2CTCTL & I2CWORD) {
      _data16[(int)ptr >> 1] = I2CDR;
      ptr = ptr + 2;
    }
    else {
      data[(int)ptr] = I2CDR & 0xFF;
      ptr++;
    }

    //    I2CIFG = 0;
    
    if (ptr == length) {
      I2CIE &= ~RXRDYIE;
      result = SUCCESS;
      if (!post readDone())
	stateI2C = IDLE;
    }
  }

  async command error_t I2CBasicAddr.write( i2c_flags_t flags,
					    uint16_t _addr, uint8_t _length,
					    uint8_t* _data ) {
    
    uint8_t _state;

    _state = stateI2C;
    if (_state == IDLE) {
      stateI2C = PACKET_WRITE;
    }

    if (_state == IDLE) {
      // perform register modifications with interrupts disabled
      atomic {
	// disable I2C to set the registers
	result = FAIL;

	U0CTL &= ~I2CEN;

	I2CSA = _addr;
	
	length = _length;
	data = _data;
	ptr = 0;

	U0CTL |= MST;
	
	I2CNDAT = _length;

	// enable I2C module
	U0CTL |= I2CEN;
	
	// set transmit mode
	I2CTCTL |= I2CTRX;

	// get an event if the receiver does not ACK
	I2CIE = TXRDYIE | NACKIE;
	I2CIFG = 0;

	// start condition and stop condition need to be sent
	I2CTCTL |= (I2CSTP | I2CSTT);
      }

      return SUCCESS;
    }

    return FAIL;
  }
  
  // handle the interrupt within this component
  void localTxData() {
    uint16_t* _data16 = (uint16_t*)data;

    if (stateI2C != PACKET_WRITE)
      return;

    // figure out where we are in the transmission
    // should only occur when I2CNDAT > 0
    if (I2CTCTL & I2CWORD) {
      I2CDR = _data16[(int)ptr >> 1];
      ptr = ptr + 2;
    }
    else {
      I2CDR = data[(int)ptr];
      ptr++;
    }

    //    I2CIFG = 0;
    
    if (ptr == length) {
      I2CIE &= ~TXRDYIE;
      result = SUCCESS;
      if (!post writeDone())
	stateI2C = IDLE;
    }
  }

  void localNoAck() {
    if ((stateI2C != PACKET_WRITE) && (stateI2C != PACKET_READ))
      return;

    I2CNDAT = 0;
    I2CIE = 0;

    // issue a stop command to clear the bus if it has not been stopped
    if (I2CDCTL & I2CBB)
      I2CTCTL |= I2CSTP;

    if (stateI2C == PACKET_WRITE) {
      if (!post writeDone())
	stateI2C = IDLE;
    }
    else if (stateI2C == PACKET_READ) {
      if (!post readDone())
	stateI2C = IDLE;
    }
  }

  async event void I2CInterrupts.fired() {
    volatile uint16_t value = I2CIV;

    switch (value) {
    case 0x0000:
      break;
    case 0x0002:
      localNoAck();
      call HplI2C.isArbitrationLostPending();
      break;
    case 0x0004:
      localNoAck();
      call HplI2C.isNoAckPending();
      break;
    case 0x0006:
      call HplI2C.isOwnAddressPending();
      break;
    case 0x0008:
      call HplI2C.isAccessReadyPending();
      break;
    case 0x000A:
      localRxData();
      break;
    case 0x000C:
      localTxData();
      break;
    case 0x000E:
      call HplI2C.isGeneralCallPending();
      break;
    case 0x0010:
      call HplI2C.isStartDetectPending();
      break;
    }
  }
}
