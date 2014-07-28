// $Id: TinyOSMainP.nc,v 1.4 2010-06-29 22:07:52 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  $Id: TinyOSMainP.nc,v 1.4 2010-06-29 22:07:52 scipio Exp $
 *
 */

/**
 * RealMain implements the TinyOS boot sequence, as documented in TEP 107.
 *
 * @author Philip Levis
 * @author Kevin Klues <klueska@cs.stanford.edu> 
 */

#ifdef DYNTHREADS 
  #define AT_SPONTANEOUS	@spontaneous()
#else
  #define AT_SPONTANEOUS
#endif

module TinyOSMainP {
  provides {
    interface Boot;
    interface ThreadInfo;
  }
  uses {
    interface Boot as TinyOSBoot;
    interface TaskScheduler;
    interface Init as PlatformInit;
    interface Init as SoftwareInit;
    interface Leds;
  }
}
implementation {
  thread_t thread_info;

  event void TinyOSBoot.booted() {
    atomic {
      /*  Initialize all of the very hardware specific stuff, such
	  as CPU settings, counters, etc. After the hardware is ready,
	  initialize the requisite software components and start
	  execution. */
	  platform_bootstrap();
    
	  // First, initialize the Scheduler so components can post tasks.
	  call TaskScheduler.init(); 
    
	  /* Initialize the platform. Then spin on the Scheduler, passing
	   * FALSE so it will not put the system to sleep if there are no
	   * more tasks; if no tasks remain, continue on to software
	   * initialization */
	  call PlatformInit.init();
	  while (call TaskScheduler.runNextTask());
	  
	  /* Initialize software components.Then spin on the Scheduler,
	   * passing FALSE so it will not put the system to sleep if there
	   * are no more tasks; if no tasks remain, the system has booted
	   * successfully.*/
	  call SoftwareInit.init(); 
	  while (call TaskScheduler.runNextTask());
    }

    /* Enable interrupts now that system is ready. */
    __nesc_enable_interrupt();

    signal Boot.booted();

    /* Spin in the TaskScheduler */
    call TaskScheduler.taskLoop();
    
  }
  
  async command error_t ThreadInfo.reset() {
    return FAIL;
  }

  async command thread_t* ThreadInfo.get() {
    return &thread_info;
  }

  default command error_t PlatformInit.init() { return SUCCESS; }
  default command error_t SoftwareInit.init() { return SUCCESS; }
  default event void Boot.booted() { }
}

