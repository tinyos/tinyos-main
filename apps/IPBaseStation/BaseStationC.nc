/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * Copyright (c) 2002-2003 Intel Corporation
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
 */

/**
 * The TinyOS 2.x base station that forwards packets between the UART
 * and radio.It replaces the GenericBase of TinyOS 1.0 and the
 * TOSBase of TinyOS 1.1.
 *
 * <p>On the serial link, BaseStation sends and receives simple active
 * messages (not particular radio packets): on the radio link, it
 * sends radio active messages, whose format depends on the network
 * stack being used. BaseStation will copy its compiled-in group ID to
 * messages moving from the serial link to the radio, and will filter
 * out incoming radio messages that do not contain that group ID.</p>
 *
 * <p>BaseStation includes queues in both directions, with a guarantee
 * that once a message enters a queue, it will eventually leave on the
 * other interface. The queues allow the BaseStation to handle load
 * spikes.</p>
 *
 * <p>BaseStation acknowledges a message arriving over the serial link
 * only if that message was successfully enqueued for delivery to the
 * radio link.</p>
 *
 * <p>The LEDS are programmed to toggle as follows:</p>
 * <ul>
 * <li><b>RED Toggle:</b>: Message bridged from serial to radio</li>
 * <li><b>GREEN Toggle:</b> Message bridged from radio to serial</li>
 * <li><b>YELLOW/BLUE Toggle:</b> Dropped message due to queue overflow in either direction</li>
 * </ul>
 *
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * @author David Gay
 * @author Philip Levis
 * @date August 10 2005
 */
#include <Ieee154.h>

configuration BaseStationC {
}
implementation {

  enum {
    // becasue we're the only one's using the radio, we're lazy and
    // don't acquire the resource.  For some reason, it seems to crash
    // occasionally if we don't do this.
    RESOURCE_IDX = unique(IEEE154_SEND_CLIENT),
  };

  components MainC, BaseStationP, LedsC;
  components Ieee154MessageC as Radio;
  components SerialDispatcherC as SerialControl, Serial802_15_4C as Serial;
  
  MainC.Boot <- BaseStationP;

  BaseStationP.RadioControl -> Radio;
  BaseStationP.SerialControl -> SerialControl;
  BaseStationP.UartSend -> Serial.Send;
  BaseStationP.UartReceive -> Serial.Receive;
  

  BaseStationP.RadioSend -> Radio;
  BaseStationP.RadioReceive -> Radio.Ieee154Receive;

  BaseStationP.RadioPacket -> Radio.Packet;
  BaseStationP.RadioIeeePacket -> Radio;
  
  BaseStationP.Leds -> LedsC;

  BaseStationP.PacketLink -> Radio;
  BaseStationP.LowPowerListening -> Radio;

  components ResetC;
  BaseStationP.Reset -> ResetC;

  components SerialDevConfC as Configure;
  BaseStationP.ConfigureSend -> Configure;
  BaseStationP.ConfigureReceive -> Configure;

  components new TimerMilliC();
  BaseStationP.ConfigureTimer -> TimerMilliC;

  components IPAddressC;
  BaseStationP.IPAddress -> IPAddressC;

#if defined(PLATFORM_IRIS) || defined(PLATFORM_MULLE)
  BaseStationP.RadioChannel -> Radio;
#else
  components CC2420ControlC;
  BaseStationP.CC2420Config -> CC2420ControlC;
#endif
}
