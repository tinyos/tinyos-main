/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

#include "Messages.h"

configuration BenchmarkCoreC {

  provides {
    interface StdControl;
    interface BenchmarkCore;
    interface Init;
  }

}

implementation {

  components BenchmarkCoreP as Core;
  
  components new DirectAMSenderC(AM_TESTMSG_T)	    as TxTest;
  components new AMReceiverC(AM_TESTMSG_T)    	    as RxTest;
  Core.RxTest -> RxTest;
  Core.TxTest -> TxTest;
  
  components ActiveMessageC;
  Core.Packet -> ActiveMessageC;
  Core.Ack -> ActiveMessageC;

#ifdef LOW_POWER_LISTENING
  #if defined(RADIO_RF230) || defined(RADIO_CC1000) || defined(RADIO_CC2420) || defined(RADIO_CC2520) || defined(RADIO_CC2420X) || defined(RADIO_RFA1)
    Core.LowPowerListening -> ActiveMessageC;
  #else
    #error " * NO PLATFORM SUPPORT FOR LOW POWER LISTENING LAYER *"
  #endif
#endif

#ifdef PACKET_LINK
  #if defined(RADIO_CC2420)
    components CC2420ActiveMessageC;
    Core.PacketLink -> CC2420ActiveMessageC;
  #elif defined(RADIO_RF230) || defined(RADIO_CC2520) || defined(RADIO_CC2420X)
    Core.PacketLink -> ActiveMessageC;
  #else
    #error " * NO PLATFORM SUPPORT FOR PACKET LINK LAYER *"
  #endif
#endif

#ifdef TRAFFIC_MONITOR
  #if defined(RADIO_RF230)
    components RF230RadioC;
    Core.TrafficMonitor -> RF230RadioC;

  #elif defined(RADIO_CC2420X)
    components CC2420XRadioC;
    Core.TrafficMonitor -> CC2420XRadioC;
  
  #elif defined(RADIO_CC2420)
    components CC2420ActiveMessageC;
    Core.TrafficMonitor -> CC2420ActiveMessageC;  
    
  #endif
#endif
  
  components new TimerMilliC() as Timer;
  Core.TestTimer -> Timer;
  
  components LedsC;
  Core.Leds -> LedsC;
  
  components new VirtualizeTimerC(TMilli,MAX_TIMER_COUNT) as TTimer;
  components new TimerMilliC() as TTimerFrom;
  TTimer.TimerFrom -> TTimerFrom;
  Core.TriggerTimer -> TTimer;

  components RandomMlcgC;
  Core.Random -> RandomMlcgC;
  Core.RandomInit -> RandomMlcgC;

  components CodeProfileC;
  Core.CodeProfile -> CodeProfileC;
  Core.CodeProfileControl -> CodeProfileC;

  StdControl = Core;
  BenchmarkCore = Core;
  Init = Core;

}
