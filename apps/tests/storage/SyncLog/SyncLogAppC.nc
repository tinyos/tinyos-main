/**
 * Test reading and writing to a log with lots of syncs. See README.txt for
 * more details.
 *
 * @author Mayur Maheshwari (mayur.maheshwari@gmail.com)
 * @author David Gay
 */

#include "StorageVolumes.h"

configuration SyncLogAppC { }
implementation {
  components SyncLogC,
    new TimerMilliC() as Timer0, new TimerMilliC() as Timer1,
    new LogStorageC(VOLUME_SYNCLOG, FALSE), SerialActiveMessageC,
    MainC, LedsC;

  SyncLogC.Leds -> LedsC;
  SyncLogC.Boot -> MainC;
  SyncLogC.Timer0 -> Timer0;
  SyncLogC.Timer1 -> Timer1;
  SyncLogC.LogWrite -> LogStorageC;
  SyncLogC.LogRead -> LogStorageC;
  SyncLogC.AMSend -> SerialActiveMessageC.AMSend[139];
  SyncLogC.AMControl -> SerialActiveMessageC;
}
