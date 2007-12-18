// $Id: DIPTrickleTimer.nc,v 1.1 2007-12-18 07:03:19 kaisenl Exp $
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
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


interface DIPTrickleTimer {

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
   * Reset the timer period to L. If called while the timer is
   * running, then a new interval (of length L) begins immediately.
   */
  command void reset();

  /**
   * The trickle timer has fired. Signaled if C &gt; K.
   */  
  event void fired();

  /**
   * Compute the window size based on DIP's estimates
   */
  event uint32_t requestWindowSize();

  /**
   * Resets the timer period to H.
   */
  command void maxInterval();
}
