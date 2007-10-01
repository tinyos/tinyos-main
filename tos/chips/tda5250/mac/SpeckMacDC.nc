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
 *
 * - Description ---------------------------------------------------------
 * low power nonpersistent CSMA MAC, rendez-vous via redundantly sent packets
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

// #define SPECKMAC_DEBUG

#ifdef SPECKMAC_PERFORMANCE
#include <Performance.h>
#endif

configuration SpeckMacDC {
  provides {
    interface SplitControl;
    interface MacSend;
    interface MacReceive;
    interface Packet;
    interface Sleeptime;
    interface ChannelCongestion;
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
        SpeckMacDP,
        RssiFixedThresholdCMC as Cca,
        new Alarm32khz16C() as Timer,
        new Alarm32khz16C() as SampleTimer,
        RandomLfsrC,
        LocalTimeC,
        DuplicateC,
        TimeDiffC;
    
    components ActiveMessageAddressC;
    SpeckMacDP.amAddress -> ActiveMessageAddressC;

    MainC.SoftwareInit -> SpeckMacDP;
              
    SplitControl = SpeckMacDP;
    MacSend = SpeckMacDP;
    MacReceive = SpeckMacDP;
    Tda5250Control = SpeckMacDP;
    UartPhyControl = SpeckMacDP;
    RadioTimeStamping = SpeckMacDP;

    ChannelCongestion = SpeckMacDP;
    
    SpeckMacDP = PacketSend;
    SpeckMacDP = PacketReceive;
    SpeckMacDP = SubPacket;
    SpeckMacDP = Packet;
    SpeckMacDP = Sleeptime;
    
    SpeckMacDP.CcaStdControl -> Cca.StdControl;
    SpeckMacDP.ChannelMonitor -> Cca.ChannelMonitor;
    SpeckMacDP.ChannelMonitorData -> Cca.ChannelMonitorData;
    SpeckMacDP.ChannelMonitorControl -> Cca.ChannelMonitorControl;
    SpeckMacDP.RssiAdcResource -> Cca.RssiAdcResource;
    
    MainC.SoftwareInit -> RandomLfsrC;
    SpeckMacDP.Random -> RandomLfsrC;

    SpeckMacDP.Timer -> Timer;
    SpeckMacDP.SampleTimer -> SampleTimer;
    SpeckMacDP.LocalTime32kHz -> LocalTimeC;

    SpeckMacDP.Duplicate -> DuplicateC;
    SpeckMacDP.TimeDiff16 -> TimeDiffC;
    SpeckMacDP.TimeDiff32 -> TimeDiffC;
    
/*    components PlatformLedsC;
    SpeckMacDP.Led0 -> PlatformLedsC.Led0;
    SpeckMacDP.Led1 -> PlatformLedsC.Led1;
    SpeckMacDP.Led2 -> PlatformLedsC.Led2;
    SpeckMacDP.Led3 -> PlatformLedsC.Led3;
*/
#ifdef SPECKMAC_DEBUG
    components new SerialDebugC() as SD;
    SpeckMacDP.SerialDebug -> SD;
#endif

#ifdef SPECKMAC_PERFORMANCE
    components new PerformanceC() as Perf;
    SpeckMacDP.Performance -> Perf;
#endif
}

