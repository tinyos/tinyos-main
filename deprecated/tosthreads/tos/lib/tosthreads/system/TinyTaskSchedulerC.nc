// $Id: TinyTaskSchedulerC.nc,v 1.2 2010-06-29 22:07:52 scipio Exp $
/*
 * Copyright (c) 2005 The Regents of the University  of California.
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
 */

/**
 * The TinyOS scheduler. It provides two interfaces: Scheduler,
 * for TinyOS to initialize and run tasks, and TaskBasic, the simplext
 * class of TinyOS tasks (reserved always at-most-once posting,
 * FIFO, parameter-free). For details and information on how to
 * replace the scheduler, refer to TEP 106.
 *
 * @author  Phil Levis
 * @author  Kevin Klues <klueska@cs.stanford.edu>
 * @date    August 7 2005
 * @see     TEP 106: Tasks and Schedulers
 */

configuration TinyTaskSchedulerC {
  provides interface TaskScheduler;
  provides interface TaskBasic[uint8_t id];
  uses interface ThreadScheduler;
}
implementation {
  components SchedulerBasicP as Sched;
  components McuSleepC as Sleep;
  TaskScheduler = Sched;
  TaskBasic = Sched;
  Sched.ThreadScheduler = ThreadScheduler;
  
  components LedsC;
  Sched.Leds -> LedsC;
}

