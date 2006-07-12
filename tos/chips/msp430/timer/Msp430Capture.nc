
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
 * @author Joe Polastre
 */

#include "Msp430Timer.h"

interface Msp430Capture
{
  /**
   * Reads the value of the last capture event in TxCCRx
   */
  async command uint16_t getEvent();

  /**
   * Set the edge that the capture should occur
   *
   * @param cm Capture Mode for edge capture.
   * enums exist for:
   *   MSP430TIMER_CM_NONE is no capture.
   *   MSP430TIMER_CM_RISING is rising edge capture.
   *   MSP430TIMER_CM_FALLING is a falling edge capture.
   *   MSP430TIMER_CM_BOTH captures on both rising and falling edges.
   */
  async command void setEdge(uint8_t cm);

  /**
   * Determine if a capture overflow is pending.
   *
   * @return TRUE if the capture register has overflowed
   */
  async command bool isOverflowPending();

  /**
   * Clear the capture overflow flag for when multiple captures occur
   */
  async command void clearOverflow();

  /**
   * Set whether the capture should occur synchronously or asynchronously.
   * TinyOS default is synchronous captures.
   * WARNING: if the capture signal is asynchronous to the timer clock,
   *          it could case a race condition (see Timer documentation
   *          in MSP430F1xx user guide)
   * @param synchronous TRUE to synchronize the timer capture with the
   *        next timer clock instead of occurring asynchronously.
   */
  async command void setSynchronous(bool synchronous);

  /**
   * Signalled when an event is captured.
   *
   * @param time The time of the capture event
   */
  async event void captured(uint16_t time);

}

