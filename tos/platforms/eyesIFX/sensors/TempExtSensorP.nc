/*
 * Copyright (c) 2007, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * @author: Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 * ========================================================================
 */
    
/**
 * The temperature sensor implementation on eyesIFX.
 * It just starts the sensor if there is an request and 
 * stops when there are no open requests left
 * (this is done via a monitor).
 *  
 * @author Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 *
 */
module TempExtSensorP {
  provides interface Read<uint16_t>;
  provides interface Resource as ReadNowResource;

  uses interface GeneralIO as TEMP;
  uses interface Resource as AdcResource;
  uses interface Read<uint16_t> as AdcRead;
}

implementation {

  uint8_t tempMonitor = 0;
  
  
  command error_t Read.read() {
    error_t error = call AdcRead.read();
    if (error == SUCCESS) {
      atomic {
      	if (tempMonitor == 0) {
       	  call TEMP.set();
        }
        ++tempMonitor;
      }
    }
    return error;
  }
   
  event void AdcRead.readDone(error_t result, uint16_t val) {
    atomic {
      --tempMonitor;
    	if (tempMonitor == 0) {
     	  call TEMP.clr();
    	}
    }
    signal Read.readDone(result, val);
  }
  
  async command error_t ReadNowResource.request() {
    error_t error = call AdcResource.request();
    if (error == SUCCESS) {
      atomic {
      	if (tempMonitor == 0) {
          call TEMP.set();
        }
        ++tempMonitor;
      }
    }   
    return error;
  }

  async command error_t ReadNowResource.immediateRequest() {
    error_t error = call AdcResource.immediateRequest();
    if (error == SUCCESS) {
      atomic {
      	if (tempMonitor == 0) {
          call TEMP.set();
        }
        ++tempMonitor;
      }
    }   
    return error;
  }

  event void AdcResource.granted() {
    signal ReadNowResource.granted();
  }
   
  async command error_t ReadNowResource.release() {
    error_t error = call AdcResource.release();
    if (error == SUCCESS) {
      atomic {
        --tempMonitor;
        if (tempMonitor == 0) {
          call TEMP.clr();
        }
      }
  	}
    return error;
  }

  async command bool ReadNowResource.isOwner() {
    return call AdcResource.isOwner();
  }
  
  
  default event void ReadNowResource.granted() {};
}
 
