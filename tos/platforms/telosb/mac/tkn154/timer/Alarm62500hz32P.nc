/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Date: 2008-11-25 09:35:09 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

generic module Alarm62500hz32P()

{
  provides interface Alarm<T62500hz,uint32_t> as Alarm;
  uses interface Alarm<T32khz,uint32_t> as AlarmFrom;
}
implementation
{
/**
 * TelosB lacks a clock with the precision and accuracy 
 * required by the 802.15.4 standard (62500 Hz, 40 ppm).
 * As a workaround, we cast one tick of the 32768 Hz clock to 
 * two 802.15.4 symbols, which introduces a small (5%) error.
 * Thus the channel access in particular in beacon-enabled PANs 
 * (slotted CSMA-CA) is not be standard-compliant!
 */

  async command void Alarm.start(uint32_t dt){ call AlarmFrom.start(dt >> 1);}
  async command void Alarm.stop(){ call AlarmFrom.stop();}
  async event void AlarmFrom.fired(){ signal Alarm.fired();}
  async command bool Alarm.isRunning(){ return call AlarmFrom.isRunning();}
  async command uint32_t Alarm.getAlarm(){ return call AlarmFrom.getAlarm() << 1;}

  async command uint32_t Alarm.getNow(){ 
    // this might shift out the most significant bit
    // that's why Alarm.startAt() is converted to a Alarm.start()
    return call AlarmFrom.getNow() << 1; 
  }

  async command void Alarm.startAt(uint32_t t0, uint32_t dt){
    // t0 occured before "now"
    atomic {
      uint32_t now = call Alarm.getNow(), elapsed;
      if (t0 < now)
        elapsed = now - t0;
      else
        elapsed = ~(t0 - now) + 1;
      if (elapsed > dt)
        dt = elapsed;
      dt -= elapsed;
      call Alarm.start(dt);
    }
  }

  /******************** Defaults ****************************/

  default async command void AlarmFrom.start(uint32_t dt){ }
  default async command void AlarmFrom.stop(){ }
  default async command bool AlarmFrom.isRunning(){ return FALSE;}
  default async event void Alarm.fired(){}
  default async command void AlarmFrom.startAt(uint32_t t0, uint32_t dt){ }
  default async command uint32_t AlarmFrom.getNow(){ return 0;}
  default async command uint32_t AlarmFrom.getAlarm(){ return 0;}
}
