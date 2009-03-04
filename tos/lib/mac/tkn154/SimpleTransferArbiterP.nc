/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
*/

/**
 * Please refer to TEP 108 for more information about this component and its
 * intended use.<br><br>
 *
 * This component provides the Resource, ArbiterInfo, and ResourceRequested
 * interfaces and uses the ResourceConfigure interface as
 * described in TEP 108.  It provides arbitration to a shared resource.
 * An queue is used to keep track of which users have put
 * in requests for the resource.  Upon the release of the resource by one
 * of these users, the queue is checked and the next user
 * that has a pending request will ge granted control of the resource.  If
 * there are no pending requests, then the resource becomes idle and any
 * user can put in a request and immediately receive access to the
 * Resource.
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philip Levis
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de> (added resource transfer)
 */
 
generic module SimpleTransferArbiterP() {
  provides {
    interface Resource[uint8_t id];
    interface ResourceRequested[uint8_t id];
    interface ResourceTransferControl;
    interface ArbiterInfo;
    interface GetNow<bool> as IsResourceRequested;
  }
  uses {
    interface ResourceConfigure[uint8_t id];
    interface ResourceQueue as Queue;
  }
}
implementation {

  enum {RES_IDLE = 0, RES_GRANTING = 1, RES_BUSY = 2};
  enum {NO_RES = 0xFF};

  uint8_t state = RES_IDLE;
  norace uint8_t resId = NO_RES;
  norace uint8_t reqResId;
  
  task void grantedTask();
  
  async command error_t Resource.request[uint8_t id]() {
    signal ResourceRequested.requested[resId]();
    atomic {
      if(state == RES_IDLE) {
        state = RES_GRANTING;
        reqResId = id;
        post grantedTask();
        return SUCCESS;
      }
      return call Queue.enqueue(id);
    }
  }

  async command error_t Resource.immediateRequest[uint8_t id]() {
    signal ResourceRequested.immediateRequested[resId]();
    atomic {
      if(state == RES_IDLE) {
        state = RES_BUSY;
        resId = id;
        call ResourceConfigure.configure[resId]();
        return SUCCESS;
      }
      return FAIL;
    }
  }
   
  async command error_t Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if(state == RES_BUSY && resId == id) {
        if(call Queue.isEmpty() == FALSE) {
          reqResId = call Queue.dequeue();
          state = RES_GRANTING;
          post grantedTask();
        }
        else {
          resId = NO_RES;
          state = RES_IDLE;
        }
        released = TRUE;
      }
    }
    if(released == TRUE) {
      call ResourceConfigure.unconfigure[id]();
      return SUCCESS;
    }
    return FAIL;
  }

  async command bool IsResourceRequested.getNow()
  {
    return !(call Queue.isEmpty());
  }

  async command error_t ResourceTransferControl.transfer(uint8_t fromClient, uint8_t toClient)
  {
    atomic {
      if (call ArbiterInfo.userId() == fromClient) {
        call ResourceConfigure.unconfigure[fromClient]();
        call ResourceConfigure.configure[resId]();
        resId = toClient;
        return SUCCESS;
      }
    }
    return FAIL;
  }
    
  /**
    Check if the Resource is currently in use
  */    
  async command bool ArbiterInfo.inUse() {
    atomic {
      if (state == RES_IDLE)
        return FALSE;
    }
    return TRUE;
  }

  /**
    Returns the current user of the Resource.
    If there is no current user, the return value
    will be 0xFF
  */      
  async command uint8_t ArbiterInfo.userId() {
    atomic {
      if(state != RES_BUSY)
        return NO_RES;
      return resId;
    }
  }

  /**
   * Returns whether you are the current owner of the resource or not
   */      
  async command uint8_t Resource.isOwner[uint8_t id]() {
    atomic {
      if(resId == id && state == RES_BUSY) return TRUE;
      else return FALSE;
    }
  }
  
  task void grantedTask() {
    atomic {
      resId = reqResId;
      state = RES_BUSY;
    }
    call ResourceConfigure.configure[resId]();
    signal Resource.granted[resId]();
  }
  
  //Default event/command handlers
  default event void Resource.granted[uint8_t id]() {
  }
  default async event void ResourceRequested.requested[uint8_t id]() {
  }
  default async event void ResourceRequested.immediateRequested[uint8_t id]() {
  }
  default async command void ResourceConfigure.configure[uint8_t id]() {
  }
  default async command void ResourceConfigure.unconfigure[uint8_t id]() {
  }
}
