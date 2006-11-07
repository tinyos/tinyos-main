// $Id: TrickleTimerMilliC.nc,v 1.3 2006-11-07 19:31:18 scipio Exp $
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
 * Configuration that encapsulates the trickle timer implementation to
 * its needed services and initialization. For details on the working
 * of the parameters, please refer to Levis et al., "A Self-Regulating
 * Algorithm for Code Maintenance and Propagation in Wireless Sensor
 * Networks," NSDI 2004.
 *
 * @param l Lower bound of the time period in seconds.
 * @param h Upper bound of the time period in seconds.
 * @param k Redundancy constant.
 * @param count How many timers to provide.
 *
 * @author Philip Levis
 * @author Gilman Tolle
 * @date   Jan 7 2006
 */ 


generic configuration TrickleTimerMilliC(uint16_t low,
					 uint16_t high,
					 uint8_t k,
					 uint8_t count) {
  provides interface TrickleTimer[uint8_t];
}
implementation {
  components new TrickleTimerImplP(low, high, k, count, 10), MainC, RandomC;
  components new TimerMilliC();
  components new BitVectorC(count) as PendingVector;
  components new BitVectorC(count) as ChangeVector;
  components LedsC;
  TrickleTimer = TrickleTimerImplP;

  TrickleTimerImplP.Timer -> TimerMilliC;
  TrickleTimerImplP.Random -> RandomC;
  TrickleTimerImplP.Changed -> ChangeVector;
  TrickleTimerImplP.Pending -> PendingVector;
  
  TrickleTimerImplP.Leds -> LedsC;
  MainC.SoftwareInit -> TrickleTimerImplP;
}

  
