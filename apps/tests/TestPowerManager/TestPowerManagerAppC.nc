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
 * This application is used to test the functionality of the non mcu power  
 * management component for non-virtualized devices.  Changes to
 * <code>MyComponentC</code> allow one to choose between different Power
 * Management policies.
 *
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @version  $Revision: 1.3 $
 * @date $Date: 2006-11-07 19:30:35 $ 
 */
 
configuration TestPowerManagerAppC{
}
implementation {
  components MainC, TestPowerManagerC, MyComponentC, LedsC, new TimerMilliC();

  TestPowerManagerC -> MainC.Boot;
  
  TestPowerManagerC.TimerMilli -> TimerMilliC;
  TestPowerManagerC.Resource0 -> MyComponentC.Resource[unique("MyComponent.Resource")];
  TestPowerManagerC.Resource1 -> MyComponentC.Resource[unique("MyComponent.Resource")];
  
  TestPowerManagerC.Leds -> LedsC;
}

