// $Id: TaskBasic.nc,v 1.6 2010-06-29 22:07:46 scipio Exp $
/*
 * Copyright (c) 2004-5 The Regents of the University  of California.  
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
 * Copyright (c) 2004-5 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
  * The basic TinyOS task interface. Components generally do not wire to
  * this interface: the nesC compiler handles it automatically through the
  * <tt>post</tt> and <tt>task</tt> keywords.
  *
  * @author Philip Levis
  * @date   January 12, 2005
  * @see    TEP 106: Tasks and Schedulers
  */ 


#include "TinyError.h"

interface TaskBasic {

  /**
   * Post this task to the TinyOS scheduler. At some later time,
   * depending on the scheduling policy, the scheduler will signal the
   * <tt>run()</tt> event. 
   *
   * @return SUCCESS if task was successfuly
   * posted; the semantics of a non-SUCCESS return value depend on the
   * implementation of this interface (the class of task).
   */
  
  async command error_t postTask();

  /**
   * Event from the scheduler to run this task. Following the TinyOS
   * concurrency model, the codes invoked from <tt>run()</tt> signals
   * execute atomically with respect to one another, but can be
   * preempted by async commands/events.
   */
  event void runTask();
}

