/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
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

/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:03:19 $ 
 * ======================================================================== 
 */
 
/**
 * Please refer to TEP 108 for more information about this component and its
 * intended use.<br><br>
 *
 * This component provides the Resource, ArbiterInfo, and Resource
 * Controller interfaces and uses the ResourceConfigure interface as
 * described in TEP 108.  It provides arbitration to a shared resource in
 * an FCFS fashion.  An array is used to keep track of which users have put
 * in requests for the resource.  Upon the release of the resource by one
 * of these users, the array is checked and the next user (in FCFS order)
 * that has a pending request will ge granted control of the resource.  If
 * there are no pending requests, then the resource becomes idle and any
 * user can put in a request and immediately receive access to the
 * Resource.
 *
 * @param <b>resourceName</b> -- The name of the Resource being shared
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philip Levis
 */
 
generic module FcfsArbiterC(char resourceName[]) {
  provides {
    interface Init;
    interface Resource[uint8_t id];
    interface ResourceController;
    interface ArbiterInfo;
  }
  uses {
    interface ResourceConfigure[uint8_t id];
  }
}
implementation {

  enum {RES_IDLE, RES_GRANTING, RES_BUSY};
  enum {NO_RES = 0xFF};
  enum {CONTROLLER_ID = uniqueCount(resourceName) + 1};

  uint8_t state = RES_IDLE;
  uint8_t resId = NO_RES;
  uint8_t reqResId = NO_RES;
  uint8_t resQ[uniqueCount(resourceName)];
  uint8_t qHead = NO_RES;
  uint8_t qTail = NO_RES;
  bool irp = FALSE;
  
  task void grantedTask();
  task void requestedTask();
  error_t queueRequest(uint8_t id);
  void grantNextRequest();
  
  bool requested(uint8_t id) {
    return resQ[id] != NO_RES || qTail == id;
  }

  /**  
    Initialize the Arbiter to the idle state
  */
  command error_t Init.init() {
    memset( resQ, NO_RES, sizeof( resQ ) );
    return SUCCESS;
  }  
  
  /**
    Request the use of the shared resource
    
    If the user has not already requested access to the 
    resource, the request will be either served immediately 
    or queued for later service in an FCFS fashion.  
    A SUCCESS value will be returned and the user will receive 
    the granted() event in synchronous context once it has 
    been given access to the resource.
    
    Whenever requests are queued, the current owner of the bus 
    will receive a requested() event, notifying him that another
    user would like to have access to the resource.
    
    If the user has already requested access to the resource and
    is waiting on a pending granted() event, an EBUSY value will 
    be returned to the caller.
  */
  async command error_t Resource.request[uint8_t id]() {
    atomic {
      if( state == RES_IDLE ) {
        state = RES_GRANTING;
        reqResId = id;
        post grantedTask();
        return SUCCESS;
      }
      if(resId == CONTROLLER_ID)
        post requestedTask();
      return queueRequest( id );
    }
  } 

  async command error_t ResourceController.request() {
    return call Resource.request[CONTROLLER_ID]();
  }
  
  /**
  * Request immediate access to the shared resource.  Requests are
  * not queued, and no granted event is returned.  A return value 
  * of SUCCESS signifies that the resource has been granted to you,
  * while a return value of EBUSY signifies that the resource is 
  * currently being used.
  */
  uint8_t tryImmediateRequest(uint8_t id) {
    atomic {
      if( state == RES_IDLE ) {
        state = RES_BUSY;
        resId = id;
        return id;
      }
      return resId;
    }     
  }
  async command error_t Resource.immediateRequest[uint8_t id]() {
    uint8_t ownerId = tryImmediateRequest(id);

    if(ownerId == id) {
      call ResourceConfigure.configure[id]();
      return SUCCESS;
    }
    else if(ownerId == CONTROLLER_ID){
      atomic {
        irp = TRUE;  //indicate that immediateRequest is pending
        reqResId = id; //Id to grant resource to if can
      }  
      signal ResourceController.requested();
      atomic {
        ownerId = resId;   //See if I have been granted the resource
        irp = FALSE;  //Indicate that immediate request no longer pending
      }
      if(ownerId == id) {
        call ResourceConfigure.configure[id]();
        return SUCCESS;
      }
      return EBUSY;
    }
    else return EBUSY;
  }  
  async command error_t ResourceController.immediateRequest() {
    return call Resource.immediateRequest[CONTROLLER_ID]();
  }
 
  /**
    Release the use of the shared resource
    
    The resource will only actually be released if
    there are no pending requests for the resource.
    If requests are pending, then the next pending request
    will be serviced, according to a Fist come first serve
    arbitration scheme.  If no requests are currently 
    pending, then the resource is released, and any 
    users can put in a request for immediate access to 
    the resource.
  */
  async command void Resource.release[uint8_t id]() {
    uint8_t currentState;
    atomic {
      if (state == RES_BUSY && resId == id) {
        if (irp)
          resId = reqResId;
	else grantNextRequest();
	call ResourceConfigure.unconfigure[id]();
      }
      currentState = state;
    }
    if(currentState == RES_IDLE)
      signal ResourceController.idle();
  } 
  async command void ResourceController.release() {
    call Resource.release[CONTROLLER_ID]();
  }
    
  /**
    Check if the Resource is currently in use
  */    
  async command bool ArbiterInfo.inUse() {
    atomic {
      if ( state == RES_IDLE )
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
    atomic return resId;
  }

  /**
   * Returns my user id.
   */      
  async command uint8_t Resource.isOwner[uint8_t id]() {
    atomic {
      if(resId == id) return TRUE;
      else return FALSE;
    }
  }
  async command uint8_t ResourceController.isOwner() {
    return call Resource.isOwner[CONTROLLER_ID]();
  }
  
  //Grant a request to the next Pending user
    //in FCFS order
  void grantNextRequest() {
    resId = NO_RES;
    if(qHead != NO_RES) {
      uint8_t id = qHead;
      qHead = resQ[qHead];
      if(qHead == NO_RES)
        qTail = NO_RES;
      resQ[id] = NO_RES;
      reqResId = id;
      state = RES_GRANTING;
      post grantedTask();
    }
    else {
      state = RES_IDLE;
    }
  }
  
  //Queue the requests so that they can be granted
    //in FCFS order after release of the resource
  error_t queueRequest(uint8_t id) {
    atomic {
      if( !requested( id ) ) { 
	      if(qHead == NO_RES )
	        qHead = id;
	      else
	        resQ[qTail] = id;
	      qTail = id;
        return SUCCESS;
      }
      return EBUSY;
    }
  }
  
  //Task for pulling the Resource.granted() signal
    //into synchronous context  
  task void grantedTask() {
    uint8_t tmpId;
    atomic {
      tmpId = resId = reqResId;
      state = RES_BUSY;
    }
    call ResourceConfigure.configure[tmpId]();
    signal Resource.granted[tmpId]();
  }

  //Task for pulling the ResourceController.requested() signal
    //into synchronous context  
  task void requestedTask() {
    uint8_t tmpId;
    atomic {
      tmpId = resId;
    }
    if(tmpId == CONTROLLER_ID)
      signal ResourceController.requested();
  }
  
  //Default event/command handlers for all of the other
    //potential users/providers of the parameterized interfaces 
    //that have not been connected to.  
  default event void Resource.granted[uint8_t id]() {
    signal ResourceController.granted();
  }
  default event void ResourceController.granted() {
  }
  default async event void ResourceController.requested() {
  }
  default async event void ResourceController.idle() {
  }
  default async command void ResourceConfigure.configure[uint8_t id]() {
  }
  default async command void ResourceConfigure.unconfigure[uint8_t id]() {
  }
}
