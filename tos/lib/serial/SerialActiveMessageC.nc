//$Id: SerialActiveMessageC.nc,v 1.4 2006-12-12 18:23:31 vlahan Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Sending active messages over the serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include "Serial.h"
configuration SerialActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
  }
  uses interface Leds;
}
implementation {
  components new SerialActiveMessageP() as AM, SerialDispatcherC;
  components SerialPacketInfoActiveMessageP as Info, MainC;

  MainC.SoftwareInit -> SerialDispatcherC;
  Leds = SerialDispatcherC;
  SplitControl = SerialDispatcherC;
  
  AMSend = AM;
  Receive = AM;
  Packet = AM;
  AMPacket = AM;
  PacketAcknowledgements = AM;
  
  AM.SubSend -> SerialDispatcherC.Send[TOS_SERIAL_ACTIVE_MESSAGE_ID];
  AM.SubReceive -> SerialDispatcherC.Receive[TOS_SERIAL_ACTIVE_MESSAGE_ID];
  
  SerialDispatcherC.SerialPacketInfo[TOS_SERIAL_ACTIVE_MESSAGE_ID] -> Info;
}
