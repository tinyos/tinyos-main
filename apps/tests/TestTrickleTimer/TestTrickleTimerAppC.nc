// $Id: TestTrickleTimerAppC.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $
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
 * Test of the trickle timers.
 * @author Philip Levis
 * @date   Jan 7 2006
 */ 

configuration TestTrickleTimerAppC {
}
implementation {
  components TestTrickleTimerAppP, MainC, RandomC;
  components new TestTrickleTimerC() as TimerA;
  components new TestTrickleTimerC() as TimerB;
  components new TestTrickleTimerC() as TimerC;
  components new TestTrickleTimerC() as TimerD;
  components new TimerMilliC();
  components new BitVectorC(1) as PendingVector;
  components new BitVectorC(1) as ChangeVector;

  //  Timer.Timer -> TimerMilliC;
  //Timer.Random -> RandomC;
  //Timer.Changed -> ChangeVector;
  //Timer.Pending -> PendingVector;
  
  MainC.SoftwareInit -> TestTrickleTimerAppP;
  TestTrickleTimerAppP.Boot -> MainC.Boot;
  
  TestTrickleTimerAppP.TimerA -> TimerA;
  TestTrickleTimerAppP.TimerB -> TimerB;
  TestTrickleTimerAppP.TimerC -> TimerC;
  TestTrickleTimerAppP.TimerD -> TimerD;
  
}

  
