/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * A low-power-listening CC1000 radio stack.
 *
 * Radio logic is split between Csma (media-access control, low-power
 * listening and general control) and SendReceive (packet reception and
 * transmission). 
 *
 * CC1000RssiP (RSSI sharing), CC1000SquelchP (noise-floor estimation)
 * and CC1000ControlP (radio configuration) provide supporting roles.
 *
 * This code has some degree of platform-independence, via the HplCC1000,
 * RssiAdc and HplCC1000Spi interfaces which must be provided by the
 * platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Joe Polastre
 * @author David Gay
 * @author Marco Langerwisch (Packet timestamping)
 */

#include "CC1000Const.h"
#include "message.h"

configuration CC1000CsmaRadioC {
  provides {
    interface SplitControl;
    interface Send;
    interface Receive;

    interface Packet;
    interface CsmaControl;
    interface CsmaBackoff;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;

    interface LowPowerListening;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
  }
}
implementation {
  components CC1000CsmaP as Csma;
  components CC1000SendReceiveP as SendReceive;
  components CC1000RssiP as Rssi;
  components CC1000SquelchP as Squelch;
  components CC1000ControlP as Control;
  components HplCC1000C as Hpl;

  components MainC, RandomC, new TimerMilliC(), ActiveMessageAddressC, BusyWaitMicroC;

  MainC.SoftwareInit -> Csma;
  MainC.SoftwareInit -> Squelch;

  SplitControl = Csma;
  Send = SendReceive;
  Receive = SendReceive;
  Packet = SendReceive;

  CsmaControl = Csma;
  CsmaBackoff = Csma;
  LowPowerListening = Csma;
  PacketAcknowledgements = SendReceive;
  LinkPacketMetadata = SendReceive;

  Csma.CC1000Control -> Control;
  Csma.Random -> RandomC;
  Csma.CC1000Squelch -> Squelch;
  Csma.WakeupTimer -> TimerMilliC;
  Csma.ByteRadio -> SendReceive;
  Csma.ByteRadioInit -> SendReceive;
  Csma.ByteRadioControl -> SendReceive;

  SendReceive.CC1000Control -> Control;
  SendReceive.HplCC1000Spi -> Hpl;
  SendReceive.amAddress -> ActiveMessageAddressC;
  SendReceive.RssiRx -> Rssi.Rssi[unique(UQ_CC1000_RSSI)];
  SendReceive.CC1000Squelch -> Squelch;

  Csma.RssiNoiseFloor -> Rssi.Rssi[unique(UQ_CC1000_RSSI)];
  Csma.RssiCheckChannel -> Rssi.Rssi[unique(UQ_CC1000_RSSI)];
  Csma.RssiPulseCheck -> Rssi.Rssi[unique(UQ_CC1000_RSSI)];
  Csma.cancelRssi -> Rssi;
  Csma.BusyWait -> BusyWaitMicroC;

  Rssi.ActualRssi -> Hpl;
  Rssi.Resource -> Hpl;
  Control.CC -> Hpl;
  Control.BusyWait -> BusyWaitMicroC;

  PacketTimeStamp32khz = SendReceive;
  PacketTimeStampMilli = SendReceive;
  PacketTimeSyncOffset = SendReceive;

  components Counter32khz32C, new CounterToLocalTimeC(T32khz);
  CounterToLocalTimeC.Counter -> Counter32khz32C;
  SendReceive.LocalTime32khz -> CounterToLocalTimeC;

  //DummyTimer is introduced to compile apps that use no timers
  components HilTimerMilliC, new TimerMilliC() as DummyTimer;
  SendReceive.LocalTimeMilli -> HilTimerMilliC;
}
