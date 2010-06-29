// $Id: DipTrickleMilliC.nc,v 1.2 2010-06-29 22:07:49 scipio Exp $
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

  
