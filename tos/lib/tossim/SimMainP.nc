/*
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

