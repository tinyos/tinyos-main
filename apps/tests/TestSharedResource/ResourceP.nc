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
 * This is an example implementation of a dedicated resource.  
 * It provides the SplitControl interface for power management
 * of the resource and an EXAMPLE ResourceOperations interface
 * for performing operations on it.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.3 $
 * @date $Date: 2006-11-07 19:30:35 $
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

