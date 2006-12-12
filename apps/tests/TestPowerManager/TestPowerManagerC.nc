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
 *
 */
 
/**
 * Please refer to TEP 115 for more information about the components
 * this application is used to test.
 *
 * This application is used to test the functionality of the non mcu power  
 * management component for non-virtualized devices.  Changes to
 * <code>MyComponentC</code> allow one to choose between different Power
 * Management policies.
 *
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @version  $Revision: 1.4 $
 * @date $Date: 2006-12-12 18:22:50 $ 
 */
 
#include "Timer.h"

module TestPowerManagerC {
  uses {
    interface Boot;  
    interface Leds;
    interface Resource as Resource0;
    interface Resource as Resource1;
    interface Timer<TMilli> as TimerMilli;
  }
}
implementation {

  #define HOLD_PERIOD 500
  #define WAIT_PERIOD 1000
  uint8_t whoHasIt;
  uint8_t waiting;
  
  //All resources try to gain access
  event void Boot.booted() {
    call Resource0.request();
    waiting = FALSE;
  }
  
  //If granted the resource, turn on an LED  
  event void Resource0.granted() {
    whoHasIt = 0;
    call Leds.led1On();
    call TimerMilli.startOneShot(HOLD_PERIOD);
  }  

  event void Resource1.granted() {
    whoHasIt = 1;
    call Leds.led2On();
    call TimerMilli.startOneShot(HOLD_PERIOD);
  }

  event void TimerMilli.fired() {
    if(waiting == TRUE) {
      waiting = FALSE;
      if(whoHasIt == 0)  {
        if(call Resource1.immediateRequest() == SUCCESS) {
          whoHasIt = 1;
          call Leds.led2On();
          call TimerMilli.startOneShot(HOLD_PERIOD);
          return;
        }
        else call Resource1.request();
      }
      if(whoHasIt == 1)
        call Resource0.request();
    }
    else {
      if(whoHasIt == 0) {
        call Leds.led1Off();
        call Resource0.release();
      }
      if(whoHasIt == 1) {
        call Leds.led2Off();
        call Resource1.release();
      }
      waiting = TRUE;
      call TimerMilli.startOneShot(WAIT_PERIOD);
    }
  }
}

