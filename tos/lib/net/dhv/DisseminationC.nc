
#include <Dhv.h>

configuration DisseminationC {
  provides interface StdControl;
}

implementation {
  components DhvLogicC;
  StdControl = DhvLogicC;
}
