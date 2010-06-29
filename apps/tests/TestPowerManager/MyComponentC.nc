/*
 * Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 * @version  $Revision: 1.6 $
 * @date $Date: 2010-06-29 22:07:25 $ 
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
  PowerManager.ResourceDefaultOwner -> Arbiter.ResourceDefaultOwner;
  PowerManager.ArbiterInfo -> Arbiter.ArbiterInfo;

  MyComponentP.Leds -> LedsC;
  MyComponentP.StartTimer -> StartTimer;
  MyComponentP.StopTimer -> StopTimer;
}

