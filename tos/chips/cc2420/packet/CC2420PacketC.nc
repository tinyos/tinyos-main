/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
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

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Chad Metcalf
 */

configuration CC2420PacketC {

  provides {
    interface CC2420Packet;
    interface PacketAcknowledgements as Acks;
    interface CC2420PacketBody;
    interface LinkPacketMetadata;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
  }

}

implementation {
  components CC2420PacketP;
  CC2420Packet         = CC2420PacketP;
  Acks                 = CC2420PacketP;
  CC2420PacketBody     = CC2420PacketP;
  LinkPacketMetadata   = CC2420PacketP;
  PacketTimeStamp32khz = CC2420PacketP;
  PacketTimeStampMilli = CC2420PacketP;
  PacketTimeSyncOffset = CC2420PacketP;

  components CC2420ActiveMessageC;
  CC2420PacketP.Packet -> CC2420ActiveMessageC;

  components Counter32khz32C, new CounterToLocalTimeC(T32khz), HilTimerMilliC;
  CounterToLocalTimeC.Counter -> Counter32khz32C;
  CC2420PacketP.LocalTime32khz -> CounterToLocalTimeC;
  CC2420PacketP.LocalTimeMilli -> HilTimerMilliC;
}
