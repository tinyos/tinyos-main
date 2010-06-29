// $Id: TrickleTimer.nc,v 1.5 2010-06-29 22:07:47 scipio Exp $
/*
 * Copyright (c) 2006 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 */

/*
 * A network trickle timer. A trickle timer has a period in the range
 * [L, H]. After firing, the period is doubled, up to H. If the period
 * is P, then the timer is scheduled to fire in the interval [0.5P, P]
 * (the second half of a period). The period can be reset to L (the
 * smallest period, and therefore the highest frequency).
 *
 * The timer may be suppressed. If a user of the interface has heard
 * enough packets from other nodes that indicate its transmitting a
 * packet would be unncessarily redundant, then the timer does not
 * fire. The timer has a constant K and a counter C. If C &gte; K, then
 * the timer does not fire. When an interval ends, C is reset to 0.
 * Calling <tt>incrementCounter</tt> increments C by one.
 *
 * For details, refer to Levis et al., "A Self-Regulating Algorithm
 * for Code Maintenance and Propagation in Wireless Sensor Networks,"
 * NSDI 2004. The component providing this interface defines the
 * constants L, H, and K.
 *
 * @author Philip Levis
 * @date   Jan 7 2006
 */ 


interface TrickleTimer {

  /**
   * Start the trickle timer. At boot, the timer period is its maximum
   * value (H). If a protocol requires starting at the minimum value
   * (e.g., fast start), then it should call <tt>reset</tt> before
   * <tt>start</tt>.
   *
   * @return error_t SUCCESS if the timer was started, EBUSY if it is already
   * running, and FAIL otherwise.
   */
  command error_t start();

  /**
   * Stop the trickle timer. This call sets the timer period to H and
   * C to 0.
   */
  command void stop();

  /**
   * Reset the timer period to L. If called while the timer is running,
   * then a new interval (of length L) begins immediately.
   */
  command void reset();

  /**
   * Increment the counter C. When an interval ends, C is set to 0.
   */
  command void incrementCounter();
  
  /**
   * The trickle timer has fired. Signaled if C &gt; K.
   */  
  event void fired();
}
