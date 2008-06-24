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

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.5 $
 * @date $Date: 2008-06-24 05:32:32 $
 */
 
#include "Resource.h"
 
generic module FcfsResourceQueueC(uint8_t size) @safe() {
  provides {
    interface Init;
    interface ResourceQueue as FcfsQueue;
  }
}
implementation {
  enum {NO_ENTRY = 0xFF};

  uint8_t resQ[size];
  uint8_t qHead = NO_ENTRY;
  uint8_t qTail = NO_ENTRY;

  command error_t Init.init() {
    memset(resQ, NO_ENTRY, sizeof(resQ));
    return SUCCESS;
  }  
  
  async command bool FcfsQueue.isEmpty() {
    return (qHead == NO_ENTRY);
  }
  	
  async command bool FcfsQueue.isEnqueued(resource_client_id_t id) {
  	return resQ[id] != NO_ENTRY || qTail == id; 
  }

  async command resource_client_id_t FcfsQueue.dequeue() {
    atomic {
      if(qHead != NO_ENTRY) {
        uint8_t id = qHead;
        qHead = resQ[qHead];
        if(qHead == NO_ENTRY)
          qTail = NO_ENTRY;
        resQ[id] = NO_ENTRY;
        return id;
      }
      return NO_ENTRY;
    }
  }
  
  async command error_t FcfsQueue.enqueue(resource_client_id_t id) {
    atomic {
      if(!(call FcfsQueue.isEnqueued(id))) {
        if(qHead == NO_ENTRY)
	        qHead = id;
	      else
  	      resQ[qTail] = id;
	      qTail = id;
        return SUCCESS;
      }
      return EBUSY;
    }
  }
}
