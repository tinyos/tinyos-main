/* -*- mode:c++; indent-tabs-mode:nil -*- 
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names 
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
 */

/**
 * Configuration for the CsmaMac.
 *
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * @author: Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 */

// #define MAC_DEBUG
configuration CsmaMacC {
  provides {
    interface SplitControl;
    interface MacSend;
    interface MacReceive;
    interface Packet;
  }
  uses {
    interface PhySend as PacketSend;
    interface PhyReceive as PacketReceive;
    interface Packet as SubPacket;
    interface Tda5250Control;  
    interface UartPhyControl;
    interface RadioTimeStamping;
  }
}
implementation {
  components  MainC,
      Tda5250RadioC,    
      CsmaMacP,
      RssiFixedThresholdCMC as Cca,
      new Alarm32khz16C() as Timer,
      new TimerMilliC() as ReRxTimer,
      DuplicateC,
      TimeDiffC,
      LocalTimeC,
      RandomLfsrC
#ifdef MAC_DEBUG
      ,PlatformLedsC
#endif
      ;
              
    MainC.SoftwareInit -> CsmaMacP;
    
    SplitControl = CsmaMacP;
    
    MacSend = CsmaMacP;
    MacReceive = CsmaMacP;
    Tda5250Control = CsmaMacP;
    UartPhyControl = CsmaMacP;
    RadioTimeStamping = CsmaMacP;
    
    CsmaMacP = Packet;
    CsmaMacP = SubPacket;
    CsmaMacP = PacketSend;
    CsmaMacP = PacketReceive;
    
    CsmaMacP.CcaStdControl -> Cca.StdControl;
    CsmaMacP.ChannelMonitor -> Cca.ChannelMonitor;
    CsmaMacP.ChannelMonitorData -> Cca.ChannelMonitorData;
    CsmaMacP.ChannelMonitorControl -> Cca.ChannelMonitorControl;
    CsmaMacP.RssiAdcResource -> Cca.RssiAdcResource;

    components ActiveMessageAddressC;
    CsmaMacP.amAddress -> ActiveMessageAddressC;

    CsmaMacP.Random -> RandomLfsrC;

    CsmaMacP.RadioResourceRequested -> Tda5250RadioC.ResourceRequested;

    CsmaMacP.Timer -> Timer;

    CsmaMacP.ReRxTimer -> ReRxTimer;

    CsmaMacP.Duplicate -> DuplicateC;
    CsmaMacP.TimeDiff16 -> TimeDiffC;
    CsmaMacP.LocalTime32kHz -> LocalTimeC;

#ifdef MAC_DEBUG
    CsmaMacP.Led0 -> PlatformLedsC.Led0;
    CsmaMacP.Led1 -> PlatformLedsC.Led1;
    CsmaMacP.Led2 -> PlatformLedsC.Led2;
    CsmaMacP.Led3 -> PlatformLedsC.Led3;
#endif    
}

