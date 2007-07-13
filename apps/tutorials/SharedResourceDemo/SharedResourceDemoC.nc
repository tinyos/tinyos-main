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
 
#include "Timer.h"
 
/**
 *
 * This application is used to test the use of Shared Resources.  
 * Three Resource users are created and all three request
 * control of the resource before any one of them is granted it.
 * Once the first user is granted control of the resource, it performs
 * some operation on it.  Once this operation has completed, a timer
 * is set to allow this user to have control of it for a specific
 * amount of time.  Once this timer expires, the resource is released
 * and then immediately requested again.  Upon releasing the resource
 * control will be granted to the next user that has requested it in 
 * round robin order.  Initial requests are made by the three resource 
 * users in the following order.<br>
 * <li> Resource 0
 * <li> Resource 2
 * <li> Resource 1
 * <br>
 * It is expected then that using a round robin policy, control of the
 * resource will be granted in the order of 0,1,2 and the Leds
 * corresponding to each resource will flash whenever this occurs.<br>
 * <li> Led 0 -> Resource 0
 * <li> Led 1 -> Resource 1
 * <li> Led 2 -> Resource 2
 * <br>
 * 
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1 $
 * @date $Date: 2007-07-13 23:43:17 $
 */

module SharedResourceDemoC {
  uses {
    interface Boot;  
    interface Leds;
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Timer<TMilli> as Timer2;
    
    interface Resource as Resource0;
    interface ResourceOperations as ResourceOperations0;
    
    interface Resource as Resource1;
    interface ResourceOperations as ResourceOperations1;
    
    interface Resource as Resource2;
    interface ResourceOperations as ResourceOperations2;
  }
}
implementation {

  #define HOLD_PERIOD 250
  
  //All resources try to gain access
  event void Boot.booted() {
    call Resource0.request();
    call Resource2.request();
    call Resource1.request();
  }
  
  //If granted the resource, run some operation  
  event void Resource0.granted() {
  	call ResourceOperations0.operation();   
  }  
  event void Resource1.granted() {
  	call ResourceOperations1.operation();
  }  
  event void Resource2.granted() {
  	call ResourceOperations2.operation();
  }  
  
  //When the operation completes, flash the LED and hold the resource for a while
  event void ResourceOperations0.operationDone(error_t error) {
  	call Timer0.startOneShot(HOLD_PERIOD);  
    call Leds.led0Toggle();
  }
  event void ResourceOperations1.operationDone(error_t error) {
    call Timer1.startOneShot(HOLD_PERIOD);  
    call Leds.led1Toggle();
  }
  event void ResourceOperations2.operationDone(error_t error) {
    call Timer2.startOneShot(HOLD_PERIOD);  
    call Leds.led2Toggle();
  }
  
  //After the hold period release the resource and request it again
  event void Timer0.fired() {
    call Resource0.release();
    call Resource0.request();
  }
  event void Timer1.fired() {
    call Resource1.release();
    call Resource1.request();
  }
  event void Timer2.fired() {
    call Resource2.release();
    call Resource2.request();
  }
}

