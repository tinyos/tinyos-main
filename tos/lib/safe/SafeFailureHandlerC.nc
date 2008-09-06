
#include "Timer.h"

configuration SafeFailureHandlerC {
}
implementation {
  components LedsC;
  components SafeFailureHandlerP;
  components BusyWaitMicroC as Wait;

  SafeFailureHandlerP.Leds -> LedsC;
  SafeFailureHandlerP.BusyWait -> Wait;
}
