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

includes Timer;
includes TOSMsg;
configuration TestPacketSerializerC {
}
implementation {
  components Main, TestPacketSerializerM
           , new AlarmMilliC() as TxTimer
           , new AlarmMilliC() as RxTimer
           , new AlarmMilliC() as CCATimer
//            , new AlarmMilliC() as TimerTimer
           , new AlarmMilliC() as SelfPollingTimer
//            , new AlarmMilliC() as SleepTimer
           , LedsC
           , TDA5250RadioC
           , RandomLfsrC
           , UARTPhyM
           , PacketSerializerM
           ;

  Main.SoftwareInit -> TDA5250RadioC.Init;
  Main.SoftwareInit -> RandomLfsrC.Init;
  Main.SoftwareInit -> LedsC.Init;
  Main.SoftwareInit -> UARTPhyM.Init;
	Main.SoftwareInit -> PacketSerializerM.Init;
  TestPacketSerializerM -> Main.Boot;

  TestPacketSerializerM.Random -> RandomLfsrC.Random;
  TestPacketSerializerM.TxTimer -> TxTimer;
  TestPacketSerializerM.RxTimer -> RxTimer;
  TestPacketSerializerM.CCATimer -> CCATimer;
//   TestPacketSerializerM.TimerTimer -> TimerTimer;
  TestPacketSerializerM.SelfPollingTimer -> SelfPollingTimer;
//   TestPacketSerializerM.SleepTimer -> SleepTimer;
  TestPacketSerializerM.Leds  -> LedsC;
  TestPacketSerializerM.TDA5250Control -> TDA5250RadioC.TDA5250Control;
  TestPacketSerializerM.RadioSplitControl -> TDA5250RadioC.SplitControl; 
  TestPacketSerializerM.Send -> PacketSerializerM.Send; 
  TestPacketSerializerM.Receive -> PacketSerializerM.Receive; 

  UARTPhyM.RadioByteComm -> TDA5250RadioC.RadioByteComm;    
   
  PacketSerializerM.RadioByteComm -> UARTPhyM.SerializerRadioByteComm;
  PacketSerializerM.PhyPacketTx -> UARTPhyM.PhyPacketTx;
  PacketSerializerM.PhyPacketRx -> UARTPhyM.PhyPacketRx;  
}



