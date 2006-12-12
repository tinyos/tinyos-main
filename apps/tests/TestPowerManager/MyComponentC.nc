/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 *
 */

/**
 * Please refer to TEP 115 for more information about the components
 * this application is used to test.
 *
 * This component is used to create a "dummy" non-virtualized component for use
 * with the TestPowerManager component.  It can be powered on and off through any
 * of the AsyncStdControl, StdControl, and SplitControl interfaces.
 *
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @version  $Revision: 1.4 $
 * @date $Date: 2006-12-12 18:22:50 $ 
 */
 
#define MYCOMPONENT_RESOURCE   "MyComponent.Resource"
configuration MyComponentC{
  provides {
    interface Resource[uint8_t];
  }
}
implementation {
  components MyComponentP, LedsC, 
             new TimerMilliC() as StartTimer, new TimerMilliC() as StopTimer,
             new FcfsArbiterC(MYCOMPONENT_RESOURCE) as Arbiter,
//              new AsyncStdControlPowerManagerC() as PowerManager;
             new AsyncStdControlDeferredPowerManagerC(750) as PowerManager;
//              new StdControlPowerManagerC() as PowerManager;
//              new StdControlDeferredPowerManagerC(750) as PowerManager;
//              new SplitControlPowerManagerC() as PowerManager;
//              new SplitControlDeferredPowerManagerC(750) as PowerManager;

  Resource = Arbiter;

  PowerManager.AsyncStdControl -> MyComponentP.AsyncStdControl;
//   PowerManager.StdControl -> MyComponentP.StdControl;
//   PowerManager.SplitControl -> MyComponentP.SplitControl;
  PowerManager.ResourceController -> Arbiter.ResourceController;
  PowerManager.ArbiterInfo -> Arbiter.ArbiterInfo;

  MyComponentP.Leds -> LedsC;
  MyComponentP.StartTimer -> StartTimer;
  MyComponentP.StopTimer -> StopTimer;
}

