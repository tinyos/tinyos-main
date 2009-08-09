
#include <BinaryShell.h>
#include "StorageVolumes.h"
#include "Deluge.h"

configuration NWProgC {
  provides interface BootImage;
} implementation {

  // send and receive pages
  components MainC, new UdpSocketC();
  components NetProgC, NWProgP;

  BootImage = NWProgP;

  components BlockStorageManagerC;
  components new BlockStorageLockClientC();
  components new BlockWriterC(VOLUME_GOLDENIMAGE) as BlockWriterDeluge0;
  components new BlockWriterC(VOLUME_DELUGE1) as BlockWriterDeluge1;
  components new BlockWriterC(VOLUME_DELUGE2) as BlockWriterDeluge2;
  components new BlockWriterC(VOLUME_DELUGE3) as BlockWriterDeluge3;

  components new BlockReaderC(VOLUME_GOLDENIMAGE) as BlockReaderDeluge0;
  components new BlockReaderC(VOLUME_DELUGE1) as BlockReaderDeluge1;
  components new BlockReaderC(VOLUME_DELUGE2) as BlockReaderDeluge2;
  components new BlockReaderC(VOLUME_DELUGE3) as BlockReaderDeluge3;

  NWProgP.Boot -> MainC;
  NWProgP.NetProg -> NetProgC;
  NWProgP.StorageMap -> BlockStorageManagerC;
  NWProgP.Recv -> UdpSocketC; // IPDispatchC.UDP[5213];
  NWProgP.Resource -> BlockStorageLockClientC;

  NWProgP.BlockWrite[VOLUME_GOLDENIMAGE] -> BlockWriterDeluge0;
  NWProgP.BlockWrite[VOLUME_DELUGE1] -> BlockWriterDeluge1;
  NWProgP.BlockWrite[VOLUME_DELUGE2] -> BlockWriterDeluge2;
  NWProgP.BlockWrite[VOLUME_DELUGE3] -> BlockWriterDeluge3;

  NWProgP.BlockRead[VOLUME_GOLDENIMAGE] -> BlockReaderDeluge0;
  NWProgP.BlockRead[VOLUME_DELUGE1] -> BlockReaderDeluge1;
  NWProgP.BlockRead[VOLUME_DELUGE2] -> BlockReaderDeluge2;
  NWProgP.BlockRead[VOLUME_DELUGE3] -> BlockReaderDeluge3;

#ifdef BINARY_SHELL
  components BinaryShellC;
  NWProgP.ShellCommand -> BinaryShellC.BinaryCommand[BSHELL_NWPROG];
#else
  components new ShellCommandC("nwprog");
  NWProgP.ShellCommand -> ShellCommandC;
#endif

  components new TimerMilliC();
  NWProgP.RebootTimer -> TimerMilliC;
  components new DelugeMetadataClientC();
  NWProgP.DelugeMetadata -> DelugeMetadataClientC;

}
