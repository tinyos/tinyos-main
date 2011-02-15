/* DO NOT MODIFY
 * This file cloned from MuxAlarmMilli32C_.nc for PRECISION_TAG=Milli and SIZE_TYPE=16 */
/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */
#include "MultiplexAlarm.h"
#include <stdint.h>

/** The base component used for multiplexing client alarms onto a
 * single hardware alarm with precision TMilli and size uint16_t.
 *
 * For debugging purposes, the DEBUG_MULTIPLEX_ALARM preprocessor
 * simple will export an interface that allows inspection of the
 * internal details of the multiplex structures.  When it is used, the
 * underlying Alarm interface that is multiplexed is also published to
 * allow more controlled testing using a controlled alarm
 * implementation.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
configuration MuxAlarmMilli16C_ {
  provides interface Alarm<TMilli, uint16_t> as ClientAlarm[ uint8_t client_id ];
} implementation {
  components new VirtualizeAlarmC(TMilli, uint16_t, uniqueCount(UQ_MuxAlarmMilli16));
  ClientAlarm = VirtualizeAlarmC.Alarm;

  components MainC;
  MainC.SoftwareInit -> VirtualizeAlarmC.Init;

  components new AlarmMilli16C();
  VirtualizeAlarmC.AlarmFrom -> AlarmMilli16C;
}
