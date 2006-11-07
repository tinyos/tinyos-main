/// $Id: HplAtm128Interrupt.nc,v 1.3 2006-11-07 19:30:44 scipio Exp $

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
 * Interface to an Atmega128 external interrupt pin
 *
 * @author Joe Polastre
 * @author Martin Turon
 */

interface HplAtm128Interrupt
{
  /** 
   * Enables ATmega128 hardware interrupt on a particular port
   */
  async command void enable();

  /** 
   * Disables ATmega128 hardware interrupt on a particular port
   */
  async command void disable();

  /** 
   * Clears the ATmega128 Interrupt Pending Flag for a particular port
   */
  async command void clear();

  /** 
   * Gets the current value of the input voltage of a port
   *
   * @return TRUE if the pin is set high, FALSE if it is set low
   */
  async command bool getValue();

  /** 
   * Sets whether the edge should be high to low or low to high.
   * @param TRUE if the interrupt should be triggered on a low to high
   *        edge transition, false for interrupts on a high to low transition
   */
  async command void edge(bool low_to_high);

  /**
   * Signalled when an interrupt occurs on a port
   */
  async event void fired();
}
