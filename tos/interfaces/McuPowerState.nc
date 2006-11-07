/// $Id: McuPowerState.nc,v 1.3 2006-11-07 19:31:17 scipio Exp $

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
 * Interface to instruct TinyOS that the low-power state of the MCU
 * may have changed. TEP 112 describes how an MCU computes this state
 * and how the Scheduler uses this interface to manage system power
 * draw.
 * 
 * @author Philip Levis
 * @date   Oct 26, 2005
 * @see    TEP 112: Microcontroller Power Management
 */

interface McuPowerState {
    /** 
     * Called by any component to tell TinyOS that the MCU low
     * power state may have changed. Generally, this should be
     * called whenever a peripheral/timer is started/stopped. 
     */
    async command void update();
}
