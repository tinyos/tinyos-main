//$Id: VirtualizeAlarmC.nc,v 1.2 2006-07-12 17:02:31 scipio Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * VirtualizeAlarmC uses a single Alarm to create up to 255 virtual alarms.
 * Note that a virtualized Alarm will have significantly more overhead than
 * an Alarm built on a hardware compare register.
 *
 * @param precision_tag A type indicating the precision of the Alarm being 
 *   virtualized.
 * @param num_alarms Number of virtual alarms to create.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

generic module VirtualizeAlarmC(typedef precision_tag, typedef size_type @integer(), int num_alarms)
{
  provides interface Init;
  provides interface Alarm<precision_tag,size_type> as Alarm[uint8_t id];
  uses interface Alarm<precision_tag,size_type> as AlarmFrom;
}
implementation
{
  enum {
    NUM_ALARMS = num_alarms,
  };

  size_type m_t0[NUM_ALARMS];
  size_type m_dt[NUM_ALARMS];
  bool m_isset[NUM_ALARMS];

  command error_t Init.init()
  {
    return SUCCESS;
  }

  void setAlarm(size_type now)
  {
    size_type t0 = 0;
    size_type dt = 0;
    bool isNotSet = TRUE;
    uint8_t id;

    for(id=0; id<NUM_ALARMS; id++)
    {
      if (m_isset[id])
      {
        size_type elapse = now - m_t0[id];
        if (m_dt[id] <= elapse)
        {
          m_t0[id] += m_dt[id];
          m_dt[id] = 0;
        }
        else
        {
          m_t0[id] = now;
          m_dt[id] -= elapse;
        }

        if (isNotSet || (m_dt[id] < dt))
        {
          t0 = m_t0[id];
          dt = m_dt[id];
          isNotSet = FALSE;
        }
      }
    }

    if (isNotSet)
      call AlarmFrom.stop();
    else
      call AlarmFrom.startAt(t0, dt);
  }
  
  // basic interface
  async command void Alarm.start[uint8_t id](size_type dt)
  {
    call Alarm.startAt[id](call AlarmFrom.getNow(), dt);
  }

  async command void Alarm.stop[uint8_t id]()
  {
    atomic
    {
      m_isset[id] = FALSE;
      setAlarm(call AlarmFrom.getNow());
    }
  }

  async event void AlarmFrom.fired()
  {
    atomic
    {
      uint8_t id;
      for(id=0; id<NUM_ALARMS; id++)
      {
        if (m_isset[id] && (m_dt[id] == 0))
        {
          m_isset[id] = FALSE;
          signal Alarm.fired[id]();
        }
      }
      setAlarm(call AlarmFrom.getNow());
    }
  }

  // extended interface
  async command bool Alarm.isRunning[uint8_t id]()
  {
    return m_isset[id];
  }

  async command void Alarm.startAt[uint8_t id](size_type t0, size_type dt)
  {
    atomic
    {
      m_t0[id] = t0;
      m_dt[id] = dt;
      m_isset[id] = TRUE;
      setAlarm(t0);
    }
  }

  async command size_type Alarm.getNow[uint8_t id]()
  {
    return call AlarmFrom.getNow();
  }

  async command size_type Alarm.getAlarm[uint8_t id]()
  {
    atomic return m_t0[id]+m_dt[id];
  }

  default async event void Alarm.fired[uint8_t id]() { }

}

