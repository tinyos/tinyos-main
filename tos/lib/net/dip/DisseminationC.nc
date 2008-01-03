
#include <Dip.h>

configuration DisseminationC {
  provides interface StdControl;
}

implementation {
  components DipLogicC;
  StdControl = DipLogicC;
}
