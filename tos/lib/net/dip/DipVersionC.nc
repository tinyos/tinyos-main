
#include <Dip.h>

configuration DipVersionC {
  provides interface DipHelp;

  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];
}

implementation {
  components DipVersionP;
  DipHelp = DipVersionP;
  DisseminationUpdate = DipVersionP;
}
