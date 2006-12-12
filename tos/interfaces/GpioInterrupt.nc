// $Id: GpioInterrupt.nc,v 1.4 2006-12-12 18:23:14 vlahan Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Jonathan Hui
 * @author Joe Polastre
 * Revision:  $Revision: 1.4 $
 *
 * Provides a microcontroller-independent presentation of interrupts
 */


interface GpioInterrupt {

  /** 
   * Enable an edge based interrupt. Calls to these functions are
   * not cumulative: only the transition type of the last called function
   * will be monitored for.
   *
   *
   * @return SUCCESS if the interrupt has been enabled
   */
  async command error_t enableRisingEdge();
  async command error_t enableFallingEdge();

  /**  
   * Diables an edge interrupt or capture interrupt
   * 
   * @return SUCCESS if the interrupt has been disabled
   */ 
  async command error_t disable();

  /**
   * Fired when an edge interrupt occurs.
   *
   * NOTE: Interrupts keep running until "disable()" is called
   */
  async event void fired();

}
