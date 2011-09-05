/*
* Copyright (c) 2009, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zsolt Szabo
*/

#include "Bma180.h"

module BmaStreamP
{
  provides
  {
    interface ReadStream<bma180_data_t>;
    interface Init;
  }

  uses
  {
    interface FastSpiByte;
    interface GpioInterrupt as Interrupt;
    interface Resource;
    interface Leds;
    interface LocalTime<TMilli>;
    interface GeneralIO as CSN;
    interface GeneralIO as PWR;
  }
}

implementation 
{
  enum
  {
    STATE_READY = 0,

    STATE_20 = 1,		// 2 buffers to be filled, 0 to be reported
    STATE_11 = 2,		// 1 buffer to be filled, 1 to be reported
    STATE_02 = 3,		// 0 buffer to be filled, 2 to be reported
    STATE_10 = 4,		// 1 buffer to be filled, 0 to be reported
    STATE_01 = 5,		// 0 buffer to be filled, 1 to be reported
    STATE_00 = 7,		// error reporting

    SAMPLING_STEP = 1,	// state increment after sampling
    REPORTING_STEP = 2,	// state increment after reporting
  };

  norace uint8_t state, temp;

  bma180_data_t * firstStart;
  uint16_t firstLength;

  norace bma180_data_t * secondStart;
  norace uint16_t secondLength;

  // ------- Fast path

  norace bma180_data_t * currentPtr;
  norace bma180_data_t * currentEnd;
  
  task void bufferDone();

  uint8_t readRegister(uint8_t address) {
    uint8_t ret;
    call CSN.clr();
    call FastSpiByte.write(0x80 | address);
    ret = call FastSpiByte.write(0);
    call CSN.set();
    return ret;
  }

  void writeRegister(uint8_t address, uint8_t newValue) {
    call CSN.clr();
    call FastSpiByte.write(0x7F & address);
    call FastSpiByte.write(newValue);
    call CSN.set();
  }


  command error_t Init.init() {
    call PWR.makeOutput();
    call PWR.set();
    call CSN.set();
    call CSN.makeOutput();
    return SUCCESS;
  }

  void readAccel() {
    if(call Resource.immediateRequest()==SUCCESS) {
      call CSN.clr();
      call FastSpiByte.write(0x88);
      currentPtr->bma180_temperature = (int8_t)call FastSpiByte.write(0);
      call CSN.set();
      call CSN.clr();
      call FastSpiByte.write(0x82);
      currentPtr->bma180_accel_x = call FastSpiByte.write(0);
      currentPtr->bma180_accel_x |= (call FastSpiByte.write(0) << 8);
      currentPtr->bma180_accel_x >>= 2;
      currentPtr->bma180_accel_y = call FastSpiByte.write(0);
      currentPtr->bma180_accel_y |= (call FastSpiByte.write(0) << 8);
      currentPtr->bma180_accel_y >>=2;
      currentPtr->bma180_accel_z = call FastSpiByte.write(0);
      currentPtr->bma180_accel_z |= (call FastSpiByte.write(0) << 8);
      currentPtr->bma180_accel_z >>=2;
      currentPtr->bma180_short_timestamp = (uint8_t)(call LocalTime.get());
      call CSN.set();
      call Resource.release();
    }
  }

  async event void Interrupt.fired()
  {    
    readAccel();
    currentPtr++;
    if( currentPtr != currentEnd ) {
      return;
    }

      currentPtr = secondStart;
    currentEnd = currentPtr + secondLength;

    if( (state += SAMPLING_STEP) != STATE_11 ) {
      call Interrupt.disable();
    }

    post bufferDone();
  }

	// ------- Slow path


  uint16_t actualPeriod;

  typedef struct free_buffer_t
  {
    uint16_t count;
    struct free_buffer_t * next;
  } free_buffer_t;

  free_buffer_t * freeBuffers;

  task void bufferDone()
  {
    uint8_t s;

    bma180_data_t * reportStart = firstStart;
    uint16_t reportLength = firstLength;

    firstStart = secondStart;
    firstLength = secondLength;

    atomic
    {
      s = state;

      if( s == STATE_11 && freeBuffers != NULL )
      {
        secondStart = (bma180_data_t *)freeBuffers;
        secondLength = freeBuffers->count;
        freeBuffers = freeBuffers->next;

        state = STATE_20;
      }
      else if( s != STATE_00 ) {
        state = s + REPORTING_STEP;
        }
    }

    if( s != STATE_00 || freeBuffers != NULL )
    {
      if( s == STATE_00 )
      {
        reportStart = (bma180_data_t *)freeBuffers;
        reportLength = freeBuffers->count;
        freeBuffers = freeBuffers->next;
      }

      signal ReadStream.bufferDone(s != STATE_00 ? SUCCESS : FAIL, reportStart, reportLength);
    }

    if( freeBuffers == NULL && (s == STATE_00 || s == STATE_01) )
    {
      signal ReadStream.readDone(s == STATE_01 ? SUCCESS : FAIL, actualPeriod); 
      state = STATE_READY;
    }
    else if( s != STATE_11 )
      post bufferDone();
  }

  command error_t ReadStream.postBuffer(bma180_data_t *buffer, uint16_t count)
  {
    free_buffer_t * * last;

    if( count < (sizeof(free_buffer_t) + 1) >> 1 )
      return ESIZE;

    atomic
    {
      if( state == STATE_10 )
      {
        secondStart = buffer;
        secondLength = count;

        state = STATE_20;
        return SUCCESS;
      }
    }

    last = & freeBuffers;

    while( *last != NULL )
      last = &((*last)->next);
	
    *last = (free_buffer_t *)buffer;
    (*last)->count = count;
    (*last)->next = NULL;

    return SUCCESS;
  }


  command error_t ReadStream.read(uint32_t period)
  {
    if( state != STATE_READY )
      return EBUSY;

    if( freeBuffers == NULL )
      return FAIL;

    // do it early
    //call Interrupt.enable();
    if(call Resource.immediateRequest() == SUCCESS) {
      temp = readRegister(0xD); //ctrl_reg0
      temp |= 0x10;                  // enable ee_w; needed for writing to addresses 0x20 .. 0x3B
      temp &=~(1<<1); //turn off sleep
      temp |= 1; //dis_wake_up
      writeRegister(0xD, temp);

      temp = readRegister(0x35); //offset_lsb1
      temp &= 0xF1;                  // clear range bits
      temp |= (BMA_RANGE<<1);
      temp |= 1;             // smp_skip
      writeRegister(0x35, temp);

      temp = readRegister(0x30); //tco_z
      temp &= 0xFC;                 // clear mode bits
      temp |= BMA_MODE;
      writeRegister(0x30, temp);

      temp = readRegister(0x20); // bw_tcs
      temp &= 0x0F;
      temp |= (BMA_BW<<4);
      writeRegister(0x20, temp);

      writeRegister(0x21, 2);//BMA_CTRL_REG3);
      call Resource.release();
    }

    firstStart = (bma180_data_t *)freeBuffers;
    firstLength = freeBuffers->count;
    freeBuffers = freeBuffers->next;

    currentPtr = firstStart;
    currentEnd = firstStart + firstLength;

    if( freeBuffers == NULL )
      state = STATE_10;
    else
    {
      secondStart = (bma180_data_t *)freeBuffers;
      secondLength = freeBuffers->count;
      freeBuffers = freeBuffers->next;

      state = STATE_20;
    }

    call Interrupt.enableRisingEdge();
      
    return SUCCESS;
  }

  event void Resource.granted() {}

  default event void ReadStream.bufferDone(error_t result, bma180_data_t* buf, uint16_t count) {}
  default event void ReadStream.readDone(error_t err, uint32_t usPeriod) {}
}
