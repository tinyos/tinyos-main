/*
 * Copyright (c) 2007, Vanderbilt University
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
