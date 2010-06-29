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
 * This application is used to test the functionality of the non mcu power  
 * management component for non-virtualized devices.  Changes to
 * <code>MyComponentC</code> allow one to choose between different Power
 * Management policies.
 *
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @version  $Revision: 1.5 $
 * @date $Date: 2010-06-29 22:07:25 $ 
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

