
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
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "TestPacketLink.h"

/**
 * Test the effectiveness of the PacketLink layer
 *
 * Transmitter == 1, 2, 3, 4, or 5 (up to MAX_TRANSMITTERS)
 * Receiver == 0
 *
 * Expect:
 *   Transmitter (ID not 0) -
 *     led1 toggling on every successfully delivered message
 *     led0 toggling on every unsuccessfully delivered message (and stay on
 *       until the next dropped packet)
 *   
 *   Receiver (ID 0) -
 *     Leds represent the binary count of sets of messages that were dropped
 *     or duplicated.
 * 
 *     Ideally, if the transmitter and receiver are in range of each other, 
 *     the receiver's LEDs should never turn on.  You can pull the receiver
 *     out of range for up to two seconds before the transmission will fail.
 *     If you aren't convinced the receiver is doing anything because its 
 *     leds aren't flashing, just turn it off and watch the transmitter's
 *     reaction.
 *
 * @author David Moss
 */
 
configuration TestPacketLinkC {
}

implementation {

  components TestPacketLinkP,
      MainC,
      ActiveMessageC,
      CC2420ActiveMessageC,
      new AMSenderC(AM_PACKETLINKMSG),
      new AMReceiverC(AM_PACKETLINKMSG),
      SerialActiveMessageC,
      new SerialAMSenderC(AM_PACKETLINKMSG),
      new TimerMilliC(),
      LedsC;
      
  TestPacketLinkP.Boot -> MainC;
  TestPacketLinkP.RadioSplitControl -> ActiveMessageC;
  TestPacketLinkP.SerialSplitControl -> SerialActiveMessageC;
  TestPacketLinkP.SerialAMSend -> SerialAMSenderC;
  TestPacketLinkP.PacketLink -> CC2420ActiveMessageC;
  TestPacketLinkP.AMPacket -> ActiveMessageC;
  TestPacketLinkP.AMSend -> AMSenderC;
  TestPacketLinkP.Receive -> AMReceiverC;
  TestPacketLinkP.Timer -> TimerMilliC;
  TestPacketLinkP.Leds -> LedsC;
  
}

