/// $Id: McuPowerOverride.nc,v 1.5 2010-06-29 22:07:46 scipio Exp $

/**
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * Interface to allow high-level components to set a lower bound for a
 * microcontroller's low power state. This is sometimes necessary,
 * e.g., if a very low power state has a long wakeup latency that will
 * violate application timing requirements. TEP 112 describes how
 * TinyOS incorporates this information when the Scheduler tells
 * the MCU to enter a low power state.
 * 
 * @author Philip Levis
 * @date   Oct 26, 2005
 * @see    TEP 112: Microconroller Power Management
 */

#include "hardware.h"

interface McuPowerOverride {

  /**
   * Called when computing the low power state, in order to allow
   * a high-level component to institute a lower bound. Because
   * this command originates deep within the basic TinyOS scheduling
   * mechanisms, it should be used very sparingly. Refer to TEP 112 for
   * details.
   *
   * @return    the lowest power state the system can enter to meet the 
   *            requirements of this component
   */
  async command mcu_power_t lowestState();
}
