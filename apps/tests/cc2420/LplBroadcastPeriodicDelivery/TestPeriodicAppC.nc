/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "TestPeriodic.h"

/**
 * This app sends a message from Transmitter node to AM_BROADCAST_ADDR
 * and waits 1000 ms between each delivery so the Rx mote's radio
 * shuts back off and has to redetect to receive the next message. 
 * Receiver: TOS_NODE_ID != 1
 * Transmitter: TOS_NODE_ID == 1
 *
 * @author David Moss
 */
 
configuration TestPeriodicAppC {
}

implementation {

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  components CC1000ActiveMessageC as Lpl;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSB) || defined(PLATFORM_SHIMMER) || defined(PLATFORM_INTELMOTE2)
  components CC2420ActiveMessageC as Lpl;
#else
#error "LPL testing not supported on this platform"
#endif

  components TestPeriodicC,
      MainC,
      ActiveMessageC,
      new TimerMilliC(),
      new AMSenderC(AM_TESTPERIODICMSG),
      new AMReceiverC(AM_TESTPERIODICMSG),
      LedsC;
      
  TestPeriodicC.Boot -> MainC;
  TestPeriodicC.SplitControl -> ActiveMessageC;
  TestPeriodicC.LowPowerListening -> Lpl;
  TestPeriodicC.AMPacket -> ActiveMessageC;
  TestPeriodicC.AMSend -> AMSenderC;
  TestPeriodicC.Receive -> AMReceiverC;
  TestPeriodicC.Packet -> ActiveMessageC;
  TestPeriodicC.Timer -> TimerMilliC;
  TestPeriodicC.Leds -> LedsC;

}

