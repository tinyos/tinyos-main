/// $Id: McuPowerOverride.nc,v 1.4 2006-12-12 18:23:14 vlahan Exp $

/**
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
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
