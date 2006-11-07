/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * MicaZ implementation of the CC2420 interrupts. FIFOP is a real
 * interrupt, while CCA and FIFO are emulated through timer polling.
 * <pre>
 *  $Id: HplCC2420InterruptsP.nc,v 1.3 2006-11-07 19:31:26 scipio Exp $
 * <pre>
 *
 * @author Philip Levis
 * @author Matt Miller
 * @version @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:26 $
 */

#include "Timer.h"

module HplCC2420InterruptsP {
  provides {
    interface GpioInterrupt as CCA;
  }
  uses {
    interface GeneralIO as CC_CCA;
    interface Timer<TMilli> as CCATimer;
  }
}
implementation {
  norace uint8_t ccaWaitForState;
  norace uint8_t ccaLastState;
  bool ccaTimerDisabled = FALSE;
  // Add stdcontrol.init/.start to setup TimerCapture timebase

  // ************* CCA Interrupt handlers and dispatch *************
  
  /**
   * enable an edge interrupt on the CCA pin
   NOT an interrupt in MICAz. Implement as a timer polled pin monitor
   */

  task void CCATask() {
    atomic {
      if (!ccaTimerDisabled) 
	call CCATimer.startOneShot(1);
    }
  }
  
  async command error_t CCA.enableRisingEdge() { 
    atomic ccaWaitForState = TRUE; //save the state we are waiting for
    atomic ccaTimerDisabled = FALSE;
    ccaLastState = call CC_CCA.get(); //get current state
    post CCATask();
    return SUCCESS;
  }

  async command error_t CCA.enableFallingEdge() { 
    atomic ccaWaitForState = FALSE; //save the state we are waiting for
    atomic ccaTimerDisabled = FALSE;
    ccaLastState = call CC_CCA.get(); //get current state
    post CCATask();
    return SUCCESS;
  }

  /**
   * disables CCA interrupts
   */
  void task stopTask() {
    atomic{
      if (ccaTimerDisabled) {
	call CCATimer.stop();
      }
    }
  }
  async command error_t CCA.disable() {
    atomic ccaTimerDisabled = TRUE;
    post stopTask();
    return SUCCESS;
  }

  /**
   * TImer Event fired so now check for CCA	level
   */
  event void CCATimer.fired() {
    uint8_t CCAState;
    atomic {
      if (ccaTimerDisabled) {
	return;
      }
    }
    //check CCA state
    CCAState = call CC_CCA.get(); //get current state
    //here if waiting for an edge
    if ((ccaLastState != ccaWaitForState) && (CCAState == ccaWaitForState)) {
      signal CCA.fired();
    }//if CCA Pin is correct and edge found
    //restart timer and try again
    ccaLastState = CCAState;
    post CCATask();
    return;
  }//CCATimer.fired

 default async event void CCA.fired() {}

} //Module HPLCC2420InterruptM
  
