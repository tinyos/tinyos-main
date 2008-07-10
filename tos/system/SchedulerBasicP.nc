// $Id: SchedulerBasicP.nc,v 1.7 2008-07-10 20:44:08 regehr Exp $

/*
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
 * SchedulerBasicP implements the default TinyOS scheduler sequence, as
 * documented in TEP 106.
 *
 * @author Philip Levis
 * @author Cory Sharp
 * @date   January 19 2005
 */

#include "hardware.h"

module SchedulerBasicP @safe() {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
  uses interface McuSleep;
}
implementation
{
  enum
  {
    NUM_TASKS = uniqueCount("TinySchedulerC.TaskBasic"),
    NO_TASK = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

  // Helper functions (internal functions) intentionally do not have atomic
  // sections.  It is left as the duty of the exported interface functions to
  // manage atomicity to minimize chances for binary code bloat.

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  inline uint8_t popTask()
  {
    if( m_head != NO_TASK )
    {
      uint8_t id = m_head;
      m_head = m_next[m_head];
      if( m_head == NO_TASK )
      {
	m_tail = NO_TASK;
      }
      m_next[id] = NO_TASK;
      return id;
    }
    else
    {
      return NO_TASK;
    }
  }
  
  bool isWaiting( uint8_t id )
  {
    return (m_next[id] != NO_TASK) || (m_tail == id);
  }

  bool pushTask( uint8_t id )
  {
    if( !isWaiting(id) )
    {
      if( m_head == NO_TASK )
      {
	m_head = id;
	m_tail = id;
      }
      else
      {
	m_next[m_tail] = id;
	m_tail = id;
      }
      return TRUE;
    }
    else
    {
      return FALSE;
    }
  }
  
  command void Scheduler.init()
  {
    atomic
    {
      memset( (void *)m_next, NO_TASK, sizeof(m_next) );
      m_head = NO_TASK;
      m_tail = NO_TASK;
    }
  }
  
  command bool Scheduler.runNextTask()
  {
    uint8_t nextTask;
    atomic
    {
      nextTask = popTask();
      if( nextTask == NO_TASK )
      {
	return FALSE;
      }
    }
    signal TaskBasic.runTask[nextTask]();
    return TRUE;
  }

  command void Scheduler.taskLoop()
  {
    for (;;)
    {
      uint8_t nextTask;

      atomic
      {
	while ((nextTask = popTask()) == NO_TASK)
	{
	  call McuSleep.sleep();
	}
      }
      signal TaskBasic.runTask[nextTask]();
    }
  }

  /**
   * Return SUCCESS if the post succeeded, EBUSY if it was already posted.
   */
  
  async command error_t TaskBasic.postTask[uint8_t id]()
  {
    atomic { return pushTask(id) ? SUCCESS : EBUSY; }
  }

  default event void TaskBasic.runTask[uint8_t id]()
  {
  }
}

