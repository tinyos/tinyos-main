/*
 * Copyright (c) 2006 Washington University in St. Louis.
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
 * This is an example implementation of a dedicated resource.  
 * It provides the SplitControl interface for power management
 * of the resource and an EXAMPLE ResourceOperations interface
 * for performing operations on it.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.2 $
 * @date $Date: 2010-06-29 22:07:40 $
 */

module ResourceP {
  provides {
    interface SplitControl;
    interface ResourceOperations;
  }
}
implementation {
	
  bool lock;
	
  task void startDone() {
  	lock = FALSE;
  	signal SplitControl.startDone(SUCCESS);
  }
  
  task void stopDone() {
  	signal SplitControl.stopDone(SUCCESS);
  }
  
  task void operationDone() {
  	lock = FALSE;
  	signal ResourceOperations.operationDone(SUCCESS);
  }
	
  command error_t SplitControl.start() {
  	post startDone();
  	return  SUCCESS;
  }
  
  command error_t SplitControl.stop() {
  	lock = TRUE;
  	post stopDone();
  	return  SUCCESS;
  }
  
  command error_t ResourceOperations.operation() {
  	if(lock == FALSE) {
      lock = TRUE;
  	  post operationDone();
  	  return SUCCESS;
  	}
  	return FAIL;
  }
}

