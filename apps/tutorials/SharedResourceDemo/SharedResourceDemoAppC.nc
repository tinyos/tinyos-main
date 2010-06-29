/*
 * Copyright (c) 2006 Washington University in St. Louis.
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
 */
 
/**
 *
 * This application is used to test the use of Shared Resources.  
 * Three Resource users are created and all three request
 * control of the resource before any one of them is granted it.
 * Once the first user is granted control of the resource, it performs
 * some operation on it.  Once this operation has completed, a timer
 * is set to allow this user to have control of it for a specific
 * amount of time.  Once this timer expires, the resource is released
 * and then immediately requested again.  Upon releasing the resource
 * control will be granted to the next user that has requested it in 
 * round robin order.  Initial requests are made by the three resource 
 * users in the following order.<br>
 * <li> Resource 0
 * <li> Resource 2
 * <li> Resource 1
 * <br>
 * It is expected then that using a round robin policy, control of the
 * resource will be granted in the order of 0,1,2 and the Leds
 * corresponding to each resource will flash whenever this occurs.<br>
 * <li> Led 0 -> Resource 0
 * <li> Led 1 -> Resource 1
 * <li> Led 2 -> Resource 2
 * <br>
 * 
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.2 $
 * @date $Date: 2010-06-29 22:07:40 $
 */
 
configuration SharedResourceDemoAppC{
}
implementation {
  components MainC,LedsC, SharedResourceDemoC as App,
  new TimerMilliC() as Timer0,
  new TimerMilliC() as Timer1,
  new TimerMilliC() as Timer2;
  App -> MainC.Boot;
  App.Leds -> LedsC;
  App.Timer0 -> Timer0;
  App.Timer1 -> Timer1;
  App.Timer2 -> Timer2;
  
  components
  new SharedResourceC() as Resource0,
  new SharedResourceC() as Resource1, 
  new SharedResourceC() as Resource2;
  App.Resource0 -> Resource0;
  App.Resource1 -> Resource1;
  App.Resource2 -> Resource2;
  App.ResourceOperations0 -> Resource0;
  App.ResourceOperations1 -> Resource1;
  App.ResourceOperations2 -> Resource2;
}
