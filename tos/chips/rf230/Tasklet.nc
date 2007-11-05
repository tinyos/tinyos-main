/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#include <Tasklet.h>

/**
 * This interface is useful in building state machines when the state 
 * transitions should be executed atomically but with interrupts enabled. 
 * All state transitions should take place in the run event handler or
 * in blocks protected by the suspend and resume commands.
 */
interface Tasklet
{
	/**
	 * This method is executed atomically. 
	 */
	tasklet_async event void run();

	/**
	 * Makes sure that the run event is called at least once more. If the 
	 * run event is currently not executing, then it  is called immediately 
	 * and this command returns only after the completion of the run event. 
	 * If the run event is currently executed, then this method returns at 
	 * once, and makes sure that the run event is called once more when 
	 * it is finished. If this method is called from a task, then by the 
	 * above rules, the run event will be called from a task as well.
	 */
	async command void schedule();

	/**
	 * Enters a critical section of the code and meakes sure that the
	 * run event is not called while in this section. No long running
	 * computation should be called from the critical session, and
	 * in particular no user event should be fired. This call is only
	 * possible from task context, otherwise we cannot guarantee that
	 * the run event is not currently running. The suspend calls
	 * can be nested. It is very important that the same number of
	 * resume commands must be called in all control paths, e.g. be very
	 * careful with the return and break commands.
	 */
	command void suspend();

	/**
	 * Leaves the critical section. This call is conly possible from 
	 * task context. If there were scheduled executions of the run
	 * event, then those will be called before this command returns.
	 */
	command void resume();
}
