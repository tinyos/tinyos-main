/*                                  tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 *
 **/

#include "Timer.h"
configuration TestUARTPhyC {
}
implementation {
  components MainC, TestUARTPhyP
           , new AlarmMilliC() as TxTimer
           , new AlarmMilliC() as RxTimer
           , new AlarmMilliC() as CCATimer
           , new AlarmMilliC() as TimerTimer
//            , new AlarmMilliC() as SelfPollingTimer
//            , new AlarmMilliC() as SleepTimer
           , LedsC
           , TDA5250RadioC
           , RandomLfsrC
           , UARTPhyP
           ;

  MainC.SoftwareInit -> TDA5250RadioC.Init;
  MainC.SoftwareInit -> RandomLfsrC.Init;
  MainC.SoftwareInit -> LedsC.Init;
  MainC.SoftwareInit -> UARTPhyP.Init;
  TestUARTPhyP -> MainC.Boot;

  TestUARTPhyP.Random -> RandomLfsrC.Random;
  TestUARTPhyP.TxTimer -> TxTimer;
  TestUARTPhyP.RxTimer -> RxTimer;
  TestUARTPhyP.CCATimer -> CCATimer;
  TestUARTPhyP.TimerTimer -> TimerTimer;
//   TestUARTPhyP.SelfPollingTimer -> SelfPollingTimer;
//   TestUARTPhyP.SleepTimer -> SleepTimer;
  TestUARTPhyP.Leds  -> LedsC;
  TestUARTPhyP.TDA5250Control -> TDA5250RadioC.TDA5250Control;
  TestUARTPhyP.RadioSplitControl -> TDA5250RadioC.SplitControl;  
  TestUARTPhyP.RadioByteComm -> UARTPhyP.SerializerRadioByteComm;
  TestUARTPhyP.PhyPacketTx -> UARTPhyP.PhyPacketTx;
  TestUARTPhyP.PhyPacketRx -> UARTPhyP.PhyPacketRx;
  
  UARTPhyP.RadioByteComm -> TDA5250RadioC.RadioByteComm;
}



