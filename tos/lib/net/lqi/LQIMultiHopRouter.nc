/*                                                                      tab:4
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
 * @author Joe Polastre
 */

#include "MultiHop.h"

configuration LQIMultiHopRouter {
  
  provides {
    interface StdControl;
    interface Receive;
    interface Send;
    interface RouteControl;
    interface LqiRouteStats;
    interface Packet;
    interface RootControl;
    interface CollectionPacket;
  }

}

implementation {

  components 
    MultiHopEngineM, 
    MultiHopLQI,
    new AMSenderC(AM_BEACONMSG) as BeaconSender,
    new AMReceiverC(AM_BEACONMSG) as BeaconReceiver,
    new AMSenderC(AM_DATAMSG) as DataSender,
    new AMReceiverC(AM_DATAMSG) as DataReceiver,
    new TimerMilliC(), 
    NoLedsC, LedsC,
    RandomC,
    ActiveMessageC,
    MainC;

  MainC.SoftwareInit -> MultiHopEngineM;
  MainC.SoftwareInit -> MultiHopLQI;
  
  components CC2420ActiveMessageC as CC2420;

  StdControl = MultiHopLQI.StdControl;
  
  Receive = MultiHopEngineM;
  Send = MultiHopEngineM;
  RouteControl = MultiHopEngineM;
  LqiRouteStats = MultiHopEngineM;
  Packet = MultiHopEngineM;
  CollectionPacket = MultiHopEngineM;
  RootControl = MultiHopLQI;
 
  MultiHopEngineM.RouteSelectCntl -> MultiHopLQI.RouteControl;
  MultiHopEngineM.RouteSelect -> MultiHopLQI;
  MultiHopEngineM.SubSend -> DataSender;
  MultiHopEngineM.SubReceive -> DataReceiver;
  MultiHopEngineM.Leds -> LedsC;
  MultiHopEngineM.AMPacket -> ActiveMessageC;
  MultiHopEngineM.SubPacket -> ActiveMessageC;
  MultiHopEngineM.PacketAcknowledgements -> ActiveMessageC;
  MultiHopEngineM.RootControl -> MultiHopLQI;
  
  MultiHopLQI.AMSend -> BeaconSender;
  MultiHopLQI.Receive -> BeaconReceiver;
  MultiHopLQI.Random -> RandomC;
  MultiHopLQI.Timer -> TimerMilliC; 
  MultiHopLQI.LqiRouteStats -> MultiHopEngineM;
  MultiHopLQI.CC2420Packet -> CC2420;
  MultiHopLQI.AMPacket -> ActiveMessageC;
  MultiHopLQI.Packet -> ActiveMessageC;
  MultiHopLQI.Leds -> NoLedsC;
}
