/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 * SimMainP implements the TOSSIM TinyOS boot sequence, as documented
 * in TEP 107. It differs from RealMainP (its mote counterpart) in that
 * it does not actually define a <tt>main</tt> function.
 *
 * @author Philip Levis
 * @date   August 17 2005
 */

static void __nesc_nido_initialise(int node);

module SimMainP {
  provides interface Boot;
  uses interface Scheduler;
  uses interface Init as PlatformInit;
  uses interface Init as SoftwareInit;
}
implementation {

  int sim_main_start_mote() @C() @spontaneous() {
    char timeBuf[128];
    atomic {
      /* First, initialize the Scheduler so components can post
	 tasks. Initialize all of the very hardware specific stuff, such
	 as CPU settings, counters, etc. After the hardware is ready,
	 initialize the requisite software components and start
	 execution.*/
      
      call Scheduler.init(); 
      
      /* Initialize the platform. Then spin on the Scheduler, passing
       * FALSE so it will not put the system to sleep if there are no
       * more tasks; if no tasks remain, continue on to software
       * initialization */
      call PlatformInit.init();    
      while (call Scheduler.runNextTask());
      
      /* Initialize software components.Then spin on the Scheduler,
       * passing FALSE so it will not put the system to sleep if there
       * are no more tasks; if no tasks remain, the system has booted
       * successfully.*/
      call SoftwareInit.init(); 
      while (call Scheduler.runNextTask());
    }
    
    /* Enable interrupts now that system is ready. */
    __nesc_enable_interrupt();

    sim_print_now(timeBuf, 128);
    dbg("SimMainP", "Mote %li signaling boot at time %s.\n", sim_node(), timeBuf);
    signal Boot.booted();
    
    /* Normally, at this point a mote enters a while(1) loop to
     * execute tasks. In TOSSIM, this call completes: posted tasks
     * are part of the global TOSSIM event loop. Look at
     * SimSchedulerBasicP for more details. */
    return 0;
  }

  default command error_t PlatformInit.init() { return SUCCESS; }
  default command error_t SoftwareInit.init() { return SUCCESS; }
  default event void Boot.booted() { }
}

