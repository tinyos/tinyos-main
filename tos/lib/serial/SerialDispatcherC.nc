//$Id: SerialDispatcherC.nc,v 1.3 2006-11-07 19:31:20 scipio Exp $

/* "Copyright (c) 2005 The Regents of the University of California.
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
 * This component provides functionality to send many different kinds
 * of serial packets on top of a general packet sending component. It
 * achieves this by knowing where the different packets in a message_t
 * exist through the SerialPacketInfo interface.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

configuration SerialDispatcherC {
  provides {
    interface Init;
    interface SplitControl;
    interface Receive[uart_id_t];
    interface Send[uart_id_t];
  }
  uses {
    interface SerialPacketInfo[uart_id_t];
    interface Leds;
  }
}
implementation {
  components SerialP, new SerialDispatcherP(),
    HdlcTranslateC,
    PlatformSerialC;

  Send = SerialDispatcherP;
  Receive = SerialDispatcherP;
  SerialPacketInfo = SerialDispatcherP.PacketInfo;
  SplitControl = SerialP;

  Init = SerialP;
  Leds = SerialP;
  Leds = SerialDispatcherP;
  Leds = HdlcTranslateC;

  SerialDispatcherP.ReceiveBytePacket -> SerialP;
  SerialDispatcherP.SendBytePacket -> SerialP;

  SerialP.SerialFrameComm -> HdlcTranslateC;
  SerialP.SerialControl -> PlatformSerialC;

  HdlcTranslateC.UartStream -> PlatformSerialC;

}
