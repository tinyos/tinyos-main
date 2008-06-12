#include "StorageVolumes.h"

configuration SerialCompressAppC {}

implementation
{
  components MainC,
             LedsC,
             SerialActiveMessageC,
             new SerialAMReceiverC(0x25),
             new SerialAMSenderC(0x25),
             new LogStorageC(VOLUME_SENSORLOG, TRUE),
             SerialCompressP;
             
  SerialCompressP.Boot -> MainC;
  SerialCompressP.Leds -> LedsC;
  SerialCompressP.LogRead -> LogStorageC;
  SerialCompressP.LogWrite -> LogStorageC;
  SerialCompressP.SerialSplitControl -> SerialActiveMessageC;
  SerialCompressP.AMSend -> SerialAMSenderC;
  SerialCompressP.Receive -> SerialAMReceiverC;
  SerialCompressP.AMPacket -> SerialActiveMessageC;
}
