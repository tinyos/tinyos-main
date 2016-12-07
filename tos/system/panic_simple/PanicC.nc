/*
 * Copyright @ 2008, 2012 Eric B. Decker
 * @author Eric B. Decker
 */

#include "panic.h"

configuration PanicC {
  provides interface Panic;
}

implementation {
  components PanicP, MainC;
  Panic = PanicP;
  MainC.SoftwareInit -> PanicP;
}
