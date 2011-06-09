
// #include <BinaryShell.h>
#include <StorageVolumes.h>

#include "Deluge.h"

configuration NWProgC {
  provides interface BootImage;
} implementation {

  // send and receive pages
  components MainC, new UdpSocketC();
  components NetProgC, NWProgP;

  BootImage = NWProgP;


  components new BlockStorageC(VOLUME_GOLDENIMAGE) as BlockDeluge0;
  components new BlockStorageC(VOLUME_DELUGE1) as BlockDeluge1;


  NWProgP.Boot -> MainC;
  NWProgP.NetProg -> NetProgC;
  // NWProgP.StorageMap -> BlockStorageManagerC;
  NWProgP.Recv -> UdpSocketC; 

  NWProgP.BlockWrite[VOLUME_GOLDENIMAGE] -> BlockDeluge0;
  NWProgP.BlockWrite[VOLUME_DELUGE1] -> BlockDeluge1;

  NWProgP.BlockRead[VOLUME_GOLDENIMAGE] -> BlockDeluge0;
  NWProgP.BlockRead[VOLUME_DELUGE1] -> BlockDeluge1;

#ifdef BINARY_SHELL
  components BinaryShellC;
  NWProgP.ShellCommand -> BinaryShellC.BinaryCommand[BSHELL_NWPROG];
#else
  components new ShellCommandC("nwprog");
  NWProgP.ShellCommand -> ShellCommandC;
#endif

  components new TimerMilliC();
  NWProgP.RebootTimer -> TimerMilliC;

  // deluge metadata stuff 
  components new DelugeMetadataClientC();
  NWProgP.DelugeMetadata -> DelugeMetadataClientC;

#if defined(PLATFORM_TELOSB)
  NWProgP.StorageMap[VOLUME_GOLDENIMAGE] -> BlockDeluge0;
  NWProgP.StorageMap[VOLUME_DELUGE1]     -> BlockDeluge1;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_IRIS) || defined(PLATFORM_EPIC) || defined(PLATFORM_MULLE)
  components At45dbStorageMapP, At45dbStorageManagerC;
  At45dbStorageMapP.At45dbVolume -> At45dbStorageManagerC;
  NWProgP.StorageMap -> At45dbStorageMapP;
#endif

}
