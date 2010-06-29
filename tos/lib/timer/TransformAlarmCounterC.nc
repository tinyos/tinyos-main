//$Id: TransformAlarmCounterC.nc,v 1.7 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * TransformAlarmCounterC decreases precision and/or widens an Alarm/Counter
 * pair. This component has a reduced interrupt overhead compared to using
 * TransformAlarmC and TransformCounterC separately. However, it is not as 
 * useful for hardware timers with multiple compare registers.
 *
 * @param to_precision_tag A type indicating the precision of the transformed
 *   interfaces.
 * @param to_size_type The type for the width of the transformed interfaces.
 * @param from_precision_tag A type indicating the precision of the original
 *   interfaces.
 * @param from_size_type The type for the width of the original interfaces.
 * @param bit_shift_right Original time units will be 2 to the power 
 *   <code>bit_shift_right</code> larger than transformed time units.
 * @param upper_count_type A type large enough to store the upper bits --
 *   those needed above from_size_type after its shift right to fill
 *   to_size_type.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @author David Gay
 */

generic module TransformAlarmCounterC(
  typedef to_precision_tag,
  typedef to_size_type @integer(),
  typedef from_precision_tag,
  typedef from_size_type @integer(),
  uint8_t bit_shift_right,
  typedef upper_count_type @integer() )
{
  provides interface Alarm<to_precision_tag,to_size_type> as Alarm;
  provides interface Counter<to_precision_tag,to_size_type> as Counter;
  uses interface Counter<from_precision_tag,from_size_type> as CounterFrom;
  uses interface Alarm<from_precision_tag,from_size_type> as AlarmFrom;
}
implementation
{
  upper_count_type m_upper;
  to_size_type m_t0;
  to_size_type m_dt;
  uint8_t m_skip_overflows;

  enum
  {
    MAX_DELAY_LOG2 = 8 * sizeof(from_size_type) - 1 - bit_shift_right,
    MAX_DELAY = ((to_size_type)1) << MAX_DELAY_LOG2,
  };

  enum
  {
    LOW_SHIFT_RIGHT = bit_shift_right,
    HIGH_SHIFT_LEFT = 8*sizeof(from_size_type) - LOW_SHIFT_RIGHT,
    NUM_UPPER_BITS = 8*sizeof(to_size_type) - 8*sizeof(from_size_type) + bit_shift_right,
    // 1. hack to remove warning when NUM_UPPER_BITS == 8*sizeof(upper_count_type)
    // 2. still provide warning if NUM_UPPER_BITS > 8*sizeof(upper_count_type)
    // 3. and allow for the strange case of NUM_UPPER_BITS == 0
    OVERFLOW_MASK = NUM_UPPER_BITS ? ((((upper_count_type)2) << (NUM_UPPER_BITS-1)) - 1) : 0,
  };

  void set_alarm();

  async command to_size_type Counter.get()
  {
    to_size_type rv = 0;
    atomic
    {
      upper_count_type high = m_upper;
      from_size_type low = call CounterFrom.get();
      if (call CounterFrom.isOverflowPending())
      {
	// If we signalled CounterFrom.overflow, that might trigger a
	// Counter.overflow, which breaks atomicity.  The right thing to do
	// increment a cached version of high without overflow signals.
	// m_upper will be handled normally as soon as the out-most atomic
	// block is left unless Clear.clearOverflow is called in the interim.
	// This is all together the expected behavior.
	high++;
	low = call CounterFrom.get();
      }
      {
	to_size_type high_to = high;
	to_size_type low_to = low >> LOW_SHIFT_RIGHT;
	rv = (high_to << HIGH_SHIFT_LEFT) | low_to;
      }
    }
    return rv;
  }

  // isOverflowPending only makes sense when it's already part of a larger
  // async block, so there's no async inside the command itself, where it
  // wouldn't do anything useful.

  async command bool Counter.isOverflowPending()
  {
    return ((m_upper & OVERFLOW_MASK) == OVERFLOW_MASK)
	   && call CounterFrom.isOverflowPending();
  }

  // clearOverflow also only makes sense inside a larger atomic block, but we
  // include the inner atomic block to ensure consistent internal state just in
  // case someone calls it non-atomically.

  async command void Counter.clearOverflow()
  {
    atomic
    {
      if (call Counter.isOverflowPending())
      {
	m_upper++;
	call CounterFrom.clearOverflow();
      }
    }
  }

  async event void CounterFrom.overflow()
  {
    atomic
    {
      m_upper++;
      if ((m_upper & OVERFLOW_MASK) == 0)
	signal Counter.overflow();

      if (m_skip_overflows && !--m_skip_overflows)
	set_alarm();
    }
  }

  async command to_size_type Alarm.getNow()
  {
    return call Counter.get();
  }

  async command to_size_type Alarm.getAlarm()
  {
    atomic return m_t0 + m_dt;
  }

  async command bool Alarm.isRunning()
  {
    atomic return call AlarmFrom.isRunning() || m_skip_overflows;
  }

  async command void Alarm.stop()
  {
    call AlarmFrom.stop();
  }

  void set_alarm()
  {
    to_size_type now = call Counter.get(), elapsed = now - m_t0, remaining;

    m_skip_overflows = 0;
    if (elapsed >= m_dt)
    {
      remaining = 0;
      m_t0 += m_dt;
      m_dt = 0;
    }
    else
    {
      remaining = m_dt - elapsed;

      /* MAX_DELAY is 1/2 an underlying counter overflow time. Just count
	 overflows if the timer is far in the future, and we'll set an
	 alarm once we're close to the deadline. */
      if (remaining > MAX_DELAY * 2)
      {
	if (remaining >= MAX_DELAY * 2 * (to_size_type)256)
	  m_skip_overflows = 255;
	else
	  m_skip_overflows = remaining / (MAX_DELAY * 2);
	return;
      }

      if (remaining > MAX_DELAY)
      {
	m_t0 = now + MAX_DELAY;
	m_dt = remaining - MAX_DELAY;
	remaining = MAX_DELAY;
      }
      else
      {
	m_t0 += m_dt;
	m_dt = 0;
      }
    }
    call AlarmFrom.startAt((from_size_type)now << bit_shift_right,
			   (from_size_type)remaining << bit_shift_right);
  }

  async command void Alarm.startAt(to_size_type t0, to_size_type dt)
  {
    atomic
    {
      m_t0 = t0;
      m_dt = dt;
      set_alarm();
    }
  }

  async command void Alarm.start(to_size_type dt)
  {
    call Alarm.startAt(call Alarm.getNow(), dt);
  }

  async event void AlarmFrom.fired()
  {
    atomic
    {
      if (m_dt == 0)
      {
	signal Alarm.fired();
      }
      else
      {
	set_alarm();
      }
    }
  }

  default async event void Alarm.fired()
  {
  }

  default async event void Counter.overflow()
  {
  }
}

