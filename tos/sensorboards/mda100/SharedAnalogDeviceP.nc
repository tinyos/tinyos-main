/*
 * Copyright (c) 2007 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date August 20th, 2007
 */

generic module SharedAnalogDeviceP(uint32_t startup_delay) {
  provides {
    interface SplitControl;
    interface Read<uint16_t>[uint8_t];
  }
  uses {
    interface Resource as AnalogDeviceResource;
    interface Timer<TMilli>;
    interface GeneralIO as EnablePin;
    interface ReadNow<uint16_t> as ActualRead;
  }
}
implementation {
  bool started = FALSE;
  bool busy = FALSE;
  uint8_t client_id;
  norace error_t read_result;
  norace uint16_t read_val;
	
  command error_t SplitControl.start() {
    error_t error;
    if(started == FALSE) {
      error = call AnalogDeviceResource.request();
      if(error == SUCCESS)
        started = TRUE;
      return error;
    }
    return FAIL;
  }

  event void AnalogDeviceResource.granted() {
    call EnablePin.makeOutput();
    call EnablePin.set();
    call Timer.startOneShot(startup_delay);
  }

  event void Timer.fired() {
    signal SplitControl.startDone(SUCCESS);
  }

  task void stopDone() {
    call AnalogDeviceResource.release();
    started = FALSE;
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    if(started == TRUE) {
      call EnablePin.clr();
      call EnablePin.makeInput();
      post stopDone();
      return SUCCESS;
    }
    else if(busy == TRUE)
      return EBUSY;
    return FAIL;
  }

  command error_t Read.read[uint8_t id]() {
    error_t error;
    if(call AnalogDeviceResource.isOwner() && busy == FALSE) {
      error = call ActualRead.read();
      if(error == SUCCESS) {
        busy = TRUE;
        client_id = id; 
      }
      return error;
    }
    return FAIL;
  }

  task void readDoneTask() {
    busy = FALSE;
    signal Read.readDone[client_id](read_result, read_val);
  }

  async event void ActualRead.readDone(error_t result, uint16_t val) {
    read_result = result;
    read_val = val;
    post readDoneTask();
  }
}
