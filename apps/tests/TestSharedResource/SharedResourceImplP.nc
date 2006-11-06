/*
 * "Copyright (c) 2006 Washington University in St. Louis.
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
 * The SharedResourceImplP component is used to wrap all of the operations
 * from a dedicated resource so that access to them is protected when 
 * it is used as a shared resource.  It uses the ArbiterInfo interface 
 * provided by an Arbiter to accomplish this.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.2 $
 * @date $Date: 2006-11-06 11:56:52 $
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

