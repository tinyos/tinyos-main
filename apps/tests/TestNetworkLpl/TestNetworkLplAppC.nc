/**
 * TestNetworkLplC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination.
 *
 * See TEP118: Dissemination, TEP 119: Collection, and TEP 123: The
 * Collection Tree Protocol for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.1 $ $Date: 2009-09-16 00:53:47 $
 */
#include "TestNetwork.h"
#include "Ctp.h"

configuration TestNetworkLplAppC {}
implementation {
  components TestNetworkLplC, MainC, LedsC, ActiveMessageC;
  components DisseminationC;
  components new DisseminatorC(uint32_t, SAMPLE_RATE_KEY) as Object32C;
  components CollectionC as Collector;
  components new CollectionSenderC(CL_TEST);
  components new TimerMilliC();
  components new DemoSensorC();
  components new SerialAMSenderC(CL_TEST);
  components SerialActiveMessageC;
#ifndef NO_DEBUG
  components new SerialAMSenderC(AM_COLLECTION_DEBUG) as UARTSender;
  components UARTDebugSenderP as DebugSender;
#endif
  components RandomC;
  components new QueueC(message_t*, 12);
  components new PoolC(message_t, 12);

  TestNetworkLplC.Boot -> MainC;
  TestNetworkLplC.RadioControl -> ActiveMessageC;
  TestNetworkLplC.SerialControl -> SerialActiveMessageC;
  TestNetworkLplC.RoutingControl -> Collector;
  TestNetworkLplC.DisseminationControl -> DisseminationC;
  TestNetworkLplC.Leds -> LedsC;
  TestNetworkLplC.Timer -> TimerMilliC;
  TestNetworkLplC.DisseminationPeriod -> Object32C;
  TestNetworkLplC.Send -> CollectionSenderC;
  TestNetworkLplC.ReadSensor -> DemoSensorC;
  TestNetworkLplC.RootControl -> Collector;
  TestNetworkLplC.Receive -> Collector.Receive[CL_TEST];
  TestNetworkLplC.UARTSend -> SerialAMSenderC.AMSend;
  TestNetworkLplC.CollectionPacket -> Collector;
  TestNetworkLplC.CtpInfo -> Collector;
  TestNetworkLplC.CtpCongestion -> Collector;
  TestNetworkLplC.Random -> RandomC;
  TestNetworkLplC.Pool -> PoolC;
  TestNetworkLplC.Queue -> QueueC;
  TestNetworkLplC.RadioPacket -> ActiveMessageC;
  TestNetworkLplC.LowPowerListening -> ActiveMessageC;
  
#ifndef NO_DEBUG
  components new PoolC(message_t, 10) as DebugMessagePool;
  components new QueueC(message_t*, 10) as DebugSendQueue;
  DebugSender.Boot -> MainC;
  DebugSender.UARTSend -> UARTSender;
  DebugSender.MessagePool -> DebugMessagePool;
  DebugSender.SendQueue -> DebugSendQueue;
  Collector.CollectionDebug -> DebugSender;
  TestNetworkLplC.CollectionDebug -> DebugSender;
#endif
  TestNetworkLplC.AMPacket -> ActiveMessageC;
}
