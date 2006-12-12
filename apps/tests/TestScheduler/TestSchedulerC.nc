// $Id: TestSchedulerC.nc,v 1.4 2006-12-12 18:22:50 vlahan Exp $

/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 * TestScheduler is a simple scheduler test that posts three CPU
 * intensive tasks of different durations. It is not intended to be
 * of great use to TinyOS programmers; rather, it is a sanity check
 * for schedulers. For details and information on how to
 * replace the scheduler, refer to TEP 106.
 *
 * @author Philip Levis
 * @date Aug 10 2005
 * @see TEP 106: Tasks and Schedulers
 */

#include "Timer.h"

module TestSchedulerC {
  uses interface Leds;
  uses interface Boot;
  uses interface TaskBasic as TaskRed;
  uses interface TaskBasic as TaskGreen;
  uses interface TaskBasic as TaskBlue;
}
implementation {

  event void TaskRed.runTask() {
    uint16_t i, j;
    for (i= 0; i < 50; i++) {
      for (j = 0; j < 10000; j++) {}
    }
    call Leds.led0Toggle();

    if (call TaskRed.postTask() == FAIL) {
      call Leds.led0Off();
    }
    else {
      call TaskRed.postTask();
    }
  }

  event void TaskGreen.runTask() {
    uint16_t i, j;
    for (i= 0; i < 25; i++) {
      for (j = 0; j < 10000; j++) {}
    }
    call Leds.led1Toggle();

    if (call TaskGreen.postTask() == FAIL) {
      call Leds.led1Off();
    }
  }

  event void TaskBlue.runTask() {
    uint16_t i, j;
    for (i= 0; i < 5; i++) {
      for (j = 0; j < 10000; j++) {}
    }
    call Leds.led2Toggle();

    if (call TaskBlue.postTask() == FAIL) {
      call Leds.led2Off();
    }
  }

  
  
  /**
   * Event from Main that TinyOS has booted: start the timer at 1Hz.
   */
  event void Boot.booted() {
    call Leds.led2Toggle();
    call TaskRed.postTask();
    call TaskGreen.postTask();
    call TaskBlue.postTask();
  }

}


