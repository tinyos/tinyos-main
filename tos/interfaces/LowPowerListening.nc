/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Low Power Listening interface
 *
 * @author Jonathan Hui
 * @author David Moss
 */

#include "message.h"

interface LowPowerListening {
  /**
   * Set this this node's radio wakeup interval, in milliseconds. After
   * each interval, the node will wakeup and check for radio activity.
   *
   * Note: The wakeup interval can be set to 0 to indicate that the radio
   * should stay on all the time but in order to get a startDone this
   * should only be done when the duty-cycling is off (after a stopDone).
   *
   * @param intervalMs the length of this node's Rx check interval, in [ms]
   */
  command void setLocalWakeupInterval(uint16_t intervalMs);
  
  /**
   * @return the local node's wakeup interval, in [ms]
   */
  command uint16_t getLocalWakeupInterval();

  /**
   * Configure this outgoing message so it can be transmitted to a neighbor mote
   * with the specified wakeup interval.
   * @param 'message_t* ONE msg' Pointer to the message that will be sent
   * @param intervalMs The receiving node's wakeup interval, in [ms]
   */
  command void setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs);

  /**
   * @param 'message_t* ONE msg'
   * @return the destination node's wakeup interval configured in this message
   */
  command uint16_t getRemoteWakeupInterval(message_t *msg);
}
