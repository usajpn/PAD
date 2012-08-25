/**
 * UsaNetworkC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination.
 *
 * See TEP118: Dissemination, TEP 119: Collection, and TEP 123: The
 * Collection Tree Protocol for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.7 $ $Date: 2009/09/16 00:51:50 $
 */
#include "UsaNetwork.h"
#include "Ctp.h"

configuration UsaNetworkAppC {}
implementation {
  components UsaNetworkC, MainC, LedsC, ActiveMessageC;
  components DisseminationC;
  components new DisseminatorC(uint32_t, SAMPLE_RATE_KEY) as Object32C;
  components CollectionC as Collector;
  components new CollectionSenderC(CL_TEST);
  components new TimerMilliC();
  components new VoltageC() as BatteryVoltage;
  components new DemoSensorC();
//  components new SerialAMSenderC(CL_TEST);
  components SerialActiveMessageC;
#ifndef NO_DEBUG
//  components new SerialAMSenderC(AM_COLLECTION_DEBUG) as UARTSender;
//  components UARTDebugSenderP as DebugSender;
#endif
  components RandomC;
  components new QueueC(message_t*, 8);
  components new PoolC(message_t, 8);

  UsaNetworkC.Boot -> MainC;
  UsaNetworkC.RadioControl -> ActiveMessageC;
  UsaNetworkC.SerialControl -> SerialActiveMessageC;
  UsaNetworkC.RoutingControl -> Collector;
  UsaNetworkC.DisseminationControl -> DisseminationC;
  UsaNetworkC.Leds -> LedsC;
  UsaNetworkC.Timer -> TimerMilliC;
  UsaNetworkC.DisseminationPeriod -> Object32C;
  UsaNetworkC.Send -> CollectionSenderC;
  UsaNetworkC.ReadSensor -> DemoSensorC;
  UsaNetworkC.RootControl -> Collector;
  UsaNetworkC.Receive -> Collector.Receive[CL_TEST];
  //UsaNetworkC.UARTSend -> SerialAMSenderC.AMSend;
  UsaNetworkC.UARTSend -> SerialActiveMessageC;
  UsaNetworkC.UARTPacket -> SerialActiveMessageC;
  UsaNetworkC.UARTAMPacket -> SerialActiveMessageC;

  UsaNetworkC.CollectionPacket -> Collector;
  UsaNetworkC.CtpInfo -> Collector;
  UsaNetworkC.CtpCongestion -> Collector;
  UsaNetworkC.Random -> RandomC;
  UsaNetworkC.Pool -> PoolC;
  UsaNetworkC.Queue -> QueueC;
  UsaNetworkC.RadioPacket -> ActiveMessageC;
  UsaNetworkC.ReadBatteryVoltage -> BatteryVoltage;
  UsaNetworkC.CtpPacket -> Collector.CtpPacket;
  UsaNetworkC.ForceParentInsertion -> Collector.ForceParentInsertion;
  
#ifndef NO_DEBUG
 // components new PoolC(message_t, 10) as DebugMessagePool;
 // components new QueueC(message_t*, 10) as DebugSendQueue;
 // DebugSender.Boot -> MainC;
 // DebugSender.UARTSend -> UARTSender;
 // DebugSender.MessagePool -> DebugMessagePool;
 // DebugSender.SendQueue -> DebugSendQueue;
 // Collector.CollectionDebug -> DebugSender;
 // UsaNetworkC.CollectionDebug -> DebugSender;
#endif
  UsaNetworkC.AMPacket -> ActiveMessageC;
}
