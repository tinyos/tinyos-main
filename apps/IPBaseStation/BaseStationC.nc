/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
z * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
// $Id: BaseStationC.nc,v 1.1 2009-01-20 00:33:22 sdhsdh Exp $

/*									tab:4
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

configuration BaseStationC {
}
implementation {
  components MainC, BaseStationP, LedsC;
#ifndef SIM
  components CC2420ActiveMessageC as Radio;
  components SerialDispatcherC as SerialControl, Serial802_15_4C as Serial;
#else 
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
#endif
  
  MainC.Boot <- BaseStationP;

  BaseStationP.RadioControl -> Radio;
#ifndef SIM
  BaseStationP.SerialControl -> SerialControl;
  BaseStationP.UartSend -> Serial.Send;
  BaseStationP.UartReceive -> Serial.Receive;
#else
  BaseStationP.SerialControl -> Serial;
  BaseStationP.UartSend -> Serial.AMSend[0];
  BaseStationP.UartReceive -> Serial.Receive[0];
#endif
  

#ifndef SIM  
  BaseStationP.RadioSend -> Radio;
  BaseStationP.RadioReceive -> Radio.IEEE154Receive;
#else
  BaseStationP.RadioSend -> Radio.AMSend[0];
  BaseStationP.RadioReceive -> Radio.ReceiveBase[0];
  BaseStationP.SerialAMPacket -> Serial;
  BaseStationP.SerialPacket -> Serial;
#endif

  BaseStationP.RadioPacket -> Radio.SubAMPacket;
  BaseStationP.RadioIEEEPacket -> Radio;
  
  BaseStationP.Leds -> LedsC;

  BaseStationP.PacketLink -> Radio;
  BaseStationP.LowPowerListening -> Radio;

  components ResetC;
  BaseStationP.Reset -> ResetC;

#ifndef SIM
  components SerialDevConfC as Configure;
  BaseStationP.ConfigureSend -> Configure;
  BaseStationP.ConfigureReceive -> Configure;

  components new TimerMilliC();
  BaseStationP.ConfigureTimer -> TimerMilliC;

  components IPAddressC;
  BaseStationP.IPAddress -> IPAddressC;

  components CC2420ControlC;
  BaseStationP.CC2420Config -> CC2420ControlC;
#endif
}
