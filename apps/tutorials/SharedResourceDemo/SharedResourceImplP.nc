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
 * The SharedResourceImplP component is used to wrap all of the operations
 * from a dedicated resource so that access to them is protected when 
 * it is used as a shared resource.  It uses the ArbiterInfo interface 
 * provided by an Arbiter to accomplish this.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.2 $
 * @date $Date: 2010-06-29 22:07:40 $
 */

module SharedResourceImplP {
  provides {
    interface ResourceOperations as SharedResourceOperations[uint8_t id];
  }
  uses {
  	interface ArbiterInfo;
  	interface ResourceOperations;
  }
}
implementation {
  uint8_t current_id = 0xFF;
  
  event void ResourceOperations.operationDone(error_t error) {
  	signal SharedResourceOperations.operationDone[current_id](error);
  }
  
  command error_t SharedResourceOperations.operation[uint8_t id]() {
  	if(call ArbiterInfo.userId() == id && call ResourceOperations.operation() == SUCCESS) {
      current_id = id;
  	  return SUCCESS;
  	}
  	return FAIL;
  }
  
  default event void SharedResourceOperations.operationDone[uint8_t id](error_t error) {}
}

