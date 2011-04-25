/*
 * Copyright (c) 2002-2011, Vanderbilt University
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
 * Author: Janos Sallai
 */

module NoSleepP {
  provides interface McuPowerOverride;
}
implementation {
  async command mcu_power_t McuPowerOverride.lowestState() {
#if defined(PLATFORM_TELOS) ||  defined(PLATFORM_TELOSA) ||  defined(PLATFORM_TELOSB) ||  defined(PLATFORM_EPIC)
    return MSP430_POWER_ACTIVE;
#elif defined(PLATFORM_MICA2) ||  defined(PLATFORM_MICAZ) ||  defined(PLATFORM_XSM) ||  defined(PLATFORM_IRIS) ||  defined(PLATFORM_ZIGBIT)
    return ATM128_POWER_IDLE;
#else
#warning Assuming 0 is the IDLE power state that prevents MCU from sleep
    return 0;
#endif
  }
}