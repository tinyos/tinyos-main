
#include <DIP.h>

configuration DisseminationC {
  provides interface StdControl;
}

implementation {
  components DIPLogicC;
  StdControl = DIPLogicC;
}
