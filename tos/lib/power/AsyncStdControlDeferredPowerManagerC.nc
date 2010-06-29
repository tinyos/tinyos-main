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
 
/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.6 $
 * $Date: 2010-06-29 22:07:50 $ 
 * ======================================================================== 
 */
 
/**
 * Please refer to TEP 115 for more information about this component and its
 * intended use.<br><br>
 *
 * This component povides a power management policy for managing the power
 * states of non-virtualized devices.  Non-virtualized devices are shared
 * using a parameterized Resource interface, and are powered down according
 * to some policy whenever there are no more pending requests to that Resource.
 * The policy implemented by this component is to delay the power down of a
 * device by some contant factor.  Such a policy is useful whenever a device
 * has a long wake-up latency.  The cost of waiting for the device to power
 * up can be avoided if the device is requested again before some predetermined
 * amount of time.<br><br>
 *
 * Powerdown of the device is done through the <code>AsyncStdControl</code>
 * interface, so this component can only be used with those devices that
 * provide that interface.<br><br>
 *
 * For devices providing either the <code>StdControl</code> or
 * <code>SplitControl</code> interfaces, please use either the
 * <code>StdControlDeferredPowerManagerC</code> component or the
 * <code>SplitControlDeferredPowerManagerC</code> component respectively.
 *
 * @param <b>delay</b> -- The amount of time the power manager should wait
 *                        before shutting down the device once it is free.
 * 
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
generic configuration AsyncStdControlDeferredPowerManagerC(uint32_t delay)
{
  uses {
    interface AsyncStdControl;

    interface PowerDownCleanup;
    interface ResourceDefaultOwner;
    interface ArbiterInfo;
  }
}
implementation {
  components new TimerMilliC(),
             new AsyncDeferredPowerManagerP(delay) as PowerManager;
 
  PowerManager.AsyncStdControl = AsyncStdControl;
  PowerManager.PowerDownCleanup = PowerDownCleanup;
 
  PowerManager.ResourceDefaultOwner = ResourceDefaultOwner;
  PowerManager.ArbiterInfo = ArbiterInfo;

  PowerManager.TimerMilli -> TimerMilliC;
}

