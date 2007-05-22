/**
 * Battery Voltage. The returned value represents the difference
 * between the battery voltage and V_BG (1.23V). The formula to convert
 * it to mV is: 1223 * 1024 / value.
 *
 * @author Razvan Musaloiu-E.
 */

#include "hardware.h"

generic configuration VoltageNowC() {
  provides interface Resource;
  provides interface ReadNow<uint16_t>;
}
implementation {
  components new AdcReadNowClientC(), VoltageP;

  ReadNow = AdcReadNowClientC;
  Resource = AdcReadNowClientC;
  AdcReadNowClientC.Atm128AdcConfig -> VoltageP;
}
