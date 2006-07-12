  /*
  * Copyright (c) 2004, Technische Universitat Berlin
  * All rights reserved.
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions
  * are met:
  * - Redistributions of source code must retain the above copyright notice,
  *   this list of conditions and the following disclaimer.
  * - Redistributions in binary form must reproduce the above copyright
  *   notice, this list of conditions and the following disclaimer in the
  *   documentation and/or other materials provided with the distribution.
  * - Neither the name of the Technische Universitat Berlin nor the names
  *   of its contributors may be used to endorse or promote products derived
  *   from this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
  * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
  * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
  * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
  * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  * - Revision -------------------------------------------------------------
  * $Revision: 1.2 $
  * $Date: 2006-07-12 16:59:17 $
  * ========================================================================
  */

  /**
  * TestPriorityArbiter Application
  * This application is used to test the functionality of the FcfsPriorityArbiter
  * component developed using the Resource and ResourceUser interfaces.
  * <br>
  * In this test there are 4 users of one ressource. The Leds indicate which
  * user is the owner of the resource:<br>
  * <li> normal priority client 1  - led 0
  * <li> normal priority client 2  - led 1
  * <li> power manager             - led 2
  * <li> high priority client      - led 0 and led 1 and led 2
  * <br><br>
  * The short flashing of the according leds inidicate that a user has requested the
  * resource. The users have the following behaviour:<br><br>
  * <li> Normal priority clients are idle for a period of time before requesting the resource.
  *      If they are granted the resource they will use it for a specific amount of time before releasing it.
  * <li> Power manager only request the resource if its idle. It releases the resource immediatly
  *       if there is a request from another client.
  * <li> High priority client behaves like a normal client but it will release the resource
  *      after a shorter period of time if there are requests from other clients.
  * <br><br>
  * The poliy of the arbiter should be FirstComeFirstServed with one exception:
  * If the high priority client requests the resource, the resource will be granted to the
  * high priority client after the release of the current owner regardless of the internal queue of the arbiter. After
  * the high priority client releases the resource the normal FCFS arbitration resumes.
  *
  * @author Kevin Klues (klues@tkn.tu-berlin.de)
  * @author Philipp Huppertz (extended test FcfsPriorityArbiter)
  */


  configuration TestPriorityArbiterAppC{
  }
  implementation {
    components  MainC,
    TestPriorityArbiterC,
    LedsC,
    BusyWaitMicroC,
    new FcfsPriorityArbiterC("Test.Arbiter.Resource") as Arbiter,
    new TimerMilliC() as TimerHigh,
    new TimerMilliC() as TimerClient1,
    new TimerMilliC() as TimerClient2;



    TestPriorityArbiterC -> MainC.Boot;
    MainC.SoftwareInit -> LedsC;
    MainC.SoftwareInit -> Arbiter;


    TestPriorityArbiterC.BusyWait -> BusyWaitMicroC;
    TestPriorityArbiterC.TimerHighClient -> TimerHigh;
    TestPriorityArbiterC.TimerClient1 -> TimerClient1;
    TestPriorityArbiterC.TimerClient2 -> TimerClient2;


    TestPriorityArbiterC.HighClient -> Arbiter.HighPriorityClient;
    TestPriorityArbiterC.PowerManager -> Arbiter.LowPriorityClient;
    TestPriorityArbiterC.Client2 -> Arbiter.Resource[unique("Test.Arbiter.Resource")];
    TestPriorityArbiterC.Client1 -> Arbiter.Resource[unique("Test.Arbiter.Resource")];

    TestPriorityArbiterC.Leds -> LedsC;
  }

