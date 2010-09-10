
#include "StorageVolumes.h"

configuration FlashShellC {
  
} implementation {
  components new ShellCommandC("flash");
  FlashShellP.ShellCommand -> ShellCommandC;

  components new BlockStorageC(VOLUME_DELUGE1);
  FlashShellP.BlockRead -> BlockStorageC;
  FlashShellP.BlockWrite -> BlockStorageC;

}
