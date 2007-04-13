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
 * MultihopOscilloscope demo application using the collection layer. 
 * See README.txt file in this directory and TEP 119: Collection.
 *
 * @author David Gay
 * @author Kyle Jamieson
 */

configuration MultihopOscilloscopeAppC { }
implementation {
  components MainC, MultihopOscilloscopeC, LedsC, new TimerMilliC(), 
    new DemoSensorC() as Sensor;

  //MainC.SoftwareInit -> Sensor;
  
  MultihopOscilloscopeC.Boot -> MainC;
  MultihopOscilloscopeC.Timer -> TimerMilliC;
  MultihopOscilloscopeC.Read -> Sensor;
  MultihopOscilloscopeC.Leds -> LedsC;

  //
  // Communication components.  These are documented in TEP 113:
  // Serial Communication, and TEP 119: Collection.
  //
  components CollectionC as Collector,  // Collection layer
    ActiveMessageC,                         // AM layer
    new CollectionSenderC(AM_OSCILLOSCOPE), // Sends multihop RF
    SerialActiveMessageC,                   // Serial messaging
    new SerialAMSenderC(AM_OSCILLOSCOPE);   // Sends to the serial port

  MultihopOscilloscopeC.RadioControl -> ActiveMessageC;
  MultihopOscilloscopeC.SerialControl -> SerialActiveMessageC;
  MultihopOscilloscopeC.RoutingControl -> Collector;

  MultihopOscilloscopeC.Send -> CollectionSenderC;
  MultihopOscilloscopeC.SerialSend -> SerialAMSenderC.AMSend;
  MultihopOscilloscopeC.Snoop -> Collector.Snoop[AM_OSCILLOSCOPE];
  MultihopOscilloscopeC.Receive -> Collector.Receive[AM_OSCILLOSCOPE];
  MultihopOscilloscopeC.RootControl -> Collector;

  components new PoolC(message_t, 10) as UARTMessagePoolP,
    new QueueC(message_t*, 10) as UARTQueueP;

  MultihopOscilloscopeC.UARTMessagePool -> UARTMessagePoolP;
  MultihopOscilloscopeC.UARTQueue -> UARTQueueP;
  
  components new PoolC(message_t, 20) as DebugMessagePool,
    new QueueC(message_t*, 20) as DebugSendQueue,
    new SerialAMSenderC(AM_LQI_DEBUG) as DebugSerialSender,
    UARTDebugSenderP as DebugSender;

  DebugSender.Boot -> MainC;
  DebugSender.UARTSend -> DebugSerialSender;
  DebugSender.MessagePool -> DebugMessagePool;
  DebugSender.SendQueue -> DebugSendQueue;
  Collector.CollectionDebug -> DebugSender;

}
