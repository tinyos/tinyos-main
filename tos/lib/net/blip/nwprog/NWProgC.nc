
#include "StorageVolumes.h"
#include "Deluge.h"

configuration NWProgC {
  provides interface BootImage;
} implementation {

  // send and receive pages
  components MainC, IPDispatchC;
  components NetProgC, NWProgP;

  BootImage = NWProgP;

  components BlockStorageManagerC;
  components new BlockStorageLockClientC();
  components new BlockWriterC(VOLUME_GOLDENIMAGE) as BlockWriterDeluge0;
  components new BlockWriterC(VOLUME_DELUGE1) as BlockWriterDeluge1;
  components new BlockWriterC(VOLUME_DELUGE2) as BlockWriterDeluge2;
  components new BlockWriterC(VOLUME_DELUGE3) as BlockWriterDeluge3;

  NWProgP.Boot -> MainC;
  NWProgP.NetProg -> NetProgC;
  NWProgP.StorageMap -> BlockStorageManagerC;
  NWProgP.Recv -> IPDispatchC.UDP[5213];
  NWProgP.Resource -> BlockStorageLockClientC;

  NWProgP.BlockWrite[VOLUME_GOLDENIMAGE] -> BlockWriterDeluge0;
  NWProgP.BlockWrite[VOLUME_DELUGE1] -> BlockWriterDeluge1;
  NWProgP.BlockWrite[VOLUME_DELUGE2] -> BlockWriterDeluge2;
  NWProgP.BlockWrite[VOLUME_DELUGE3] -> BlockWriterDeluge3;

  components new ShellCommandC("nwprog");
  NWProgP.ShellCommand -> ShellCommandC;
  components new TimerMilliC();
  NWProgP.RebootTimer -> TimerMilliC;
  components new DelugeMetadataClientC();
  NWProgP.DelugeMetadata -> DelugeMetadataClientC;

}
