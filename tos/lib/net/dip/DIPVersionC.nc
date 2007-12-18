
#include <DIP.h>

configuration DIPVersionC {
  provides interface DIPHelp;

  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];
}

implementation {
  components DIPVersionP;
  DIPHelp = DIPVersionP;
  DisseminationUpdate = DIPVersionP;
}
