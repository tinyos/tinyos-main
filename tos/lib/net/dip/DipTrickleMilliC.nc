// $Id: DipTrickleMilliC.nc,v 1.1 2008-01-03 21:30:35 kaisenl Exp $
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


configuration DipTrickleMilliC {
  provides interface DipTrickleTimer as TrickleTimer;
}
implementation {
  components DipTrickleMilliP as TrickleP;
  components MainC, RandomC;
  components new TimerMilliC() as PeriodicIntervalTimer;
  components new TimerMilliC() as SingleEventTimer;
  components LedsC;
  TrickleTimer = TrickleP;

  TrickleP.PeriodicIntervalTimer -> PeriodicIntervalTimer;
  TrickleP.SingleEventTimer -> SingleEventTimer;
  TrickleP.Random -> RandomC;
  
  TrickleP.Leds -> LedsC;
  MainC.SoftwareInit -> TrickleP;
}

  
