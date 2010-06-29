// $Id: TestSchedulerC.nc,v 1.5 2010-06-29 22:07:25 scipio Exp $

/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.
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


