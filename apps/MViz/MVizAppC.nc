/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * MViz demo application using the collection layer. 
 * See README.txt file in this directory and TEP 119: Collection.
 *
 * @author David Gay
 * @author Kyle Jamieson
 * @author Philip Levis
 */

#include <MViz.h>

configuration MVizAppC { }
implementation {
  components MainC, MVizC, LedsC, new TimerMilliC(), 
    new MVizSensorC() as Sensor, RandomC;

  //MainC.SoftwareInit -> Sensor;
  
  MVizC.Boot -> MainC;
  MVizC.Timer -> TimerMilliC;
  MVizC.Read -> Sensor;
  MVizC.Leds -> LedsC;
  MVizC.Random -> RandomC;
  //
  // Communication components.  These are documented in TEP 113:
  // Serial Communication, and TEP 119: Collection.
  //
  components CollectionC as Collector,  // Collection layer
    ActiveMessageC,                         // AM layer
    new CollectionSenderC(AM_MVIZ_MSG), // Sends multihop RF
    SerialActiveMessageC,                   // Serial messaging
    new SerialAMSenderC(AM_MVIZ_MSG);   // Sends to the serial port

  components CtpP as Ctp;
  
  MVizC.RadioControl -> ActiveMessageC;
  MVizC.SerialControl -> SerialActiveMessageC;
  MVizC.RoutingControl -> Collector;

  MVizC.Send -> CollectionSenderC;
  MVizC.SerialSend -> SerialAMSenderC.AMSend;
  MVizC.Snoop -> Collector.Snoop[AM_MVIZ_MSG];
  MVizC.Receive -> Collector.Receive[AM_MVIZ_MSG];
  MVizC.RootControl -> Collector;
  MVizC.CtpInfo -> Ctp;
  MVizC.LinkEstimator -> Ctp;

}
