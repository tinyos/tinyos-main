//$Id: Serial802_15_4C.nc,v 1.1 2008-05-13 00:15:21 vlahan Exp $

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
 * Implementation of communication 802.15.4 message_t packets over the
 * serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include "Serial.h"
configuration Serial802_15_4C {
  provides {
    interface Send;
    interface Receive;
  }
  uses interface Leds;
}
implementation { 
  components MainC, SerialPacketInfo802_15_4P, SerialDispatcherC;

  MainC.SoftwareInit -> SerialDispatcherC;
  Leds = SerialDispatcherC;
  Send = SerialDispatcherC.Send[TOS_SERIAL_802_15_4_ID];
  Receive = SerialDispatcherC.Receive[TOS_SERIAL_802_15_4_ID];
  SerialDispatcherC.SerialPacketInfo[TOS_SERIAL_802_15_4_ID] -> SerialPacketInfo802_15_4P.Info;
}
