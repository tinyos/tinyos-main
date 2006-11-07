/*                                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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

#include <Timer.h>
#include <message.h>

configuration TestPacketSerializerC {
}
implementation {
  components MainC, TestPacketSerializerP
           , new AlarmMilliC() as TxTimer
           , new AlarmMilliC() as RxTimer
           , new AlarmMilliC() as CCATimer
//            , new AlarmMilliC() as TimerTimer
           , new AlarmMilliC() as SelfPollingTimer
//            , new AlarmMilliC() as SleepTimer
           , LedsC
           , TDA5250RadioC
           , RandomLfsrC
           , UARTPhyP
           , PacketSerializerP
           ;

  MainC.SoftwareInit -> TDA5250RadioC.Init;
  MainC.SoftwareInit -> RandomLfsrC.Init;
  MainC.SoftwareInit -> LedsC.Init;
  MainC.SoftwareInit -> UARTPhyP.Init;
  MainC.SoftwareInit -> PacketSerializerP.Init;
  TestPacketSerializerP -> MainC.Boot;

  TestPacketSerializerP.Random -> RandomLfsrC.Random;
  TestPacketSerializerP.TxTimer -> TxTimer;
  TestPacketSerializerP.RxTimer -> RxTimer;
  TestPacketSerializerP.CCATimer -> CCATimer;
//   TestPacketSerializerP.TimerTimer -> TimerTimer;
  TestPacketSerializerP.SelfPollingTimer -> SelfPollingTimer;
//   TestPacketSerializerP.SleepTimer -> SleepTimer;
  TestPacketSerializerP.Leds  -> LedsC;
  TestPacketSerializerP.TDA5250Control -> TDA5250RadioC.TDA5250Control;
  TestPacketSerializerP.RadioSplitControl -> TDA5250RadioC.SplitControl; 
  TestPacketSerializerP.Send -> PacketSerializerP.Send; 
  TestPacketSerializerP.Receive -> PacketSerializerP.Receive; 

  UARTPhyP.RadioByteComm -> TDA5250RadioC.RadioByteComm;    
   
  PacketSerializerP.RadioByteComm -> UARTPhyP.SerializerRadioByteComm;
  PacketSerializerP.PhyPacketTx -> UARTPhyP.PhyPacketTx;
  PacketSerializerP.PhyPacketRx -> UARTPhyP.PhyPacketRx;  
}



