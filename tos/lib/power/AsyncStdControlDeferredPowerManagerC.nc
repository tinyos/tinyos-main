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
 
/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:29 $ 
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
    interface ResourceController;
    interface ArbiterInfo;
  }
}
implementation {
  components new TimerMilliC(),
             new AsyncDeferredPowerManagerP(delay) as PowerManager;
 
  PowerManager.AsyncStdControl = AsyncStdControl;
  PowerManager.PowerDownCleanup = PowerDownCleanup;
 
  PowerManager.ResourceController = ResourceController;
  PowerManager.ArbiterInfo = ArbiterInfo;

  PowerManager.TimerMilli -> TimerMilliC;
}

