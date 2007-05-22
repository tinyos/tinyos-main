/**
 * Battery Voltage. The returned value represents the difference
 * between the battery voltage and V_BG (1.23V). The formula to convert
 * it to mV is: 1223 * 1024 / value.
 *
 * @author Razvan Musaloiu-E.
 */

#include "hardware.h"

generic configuration VoltageStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components VoltageP, new AdcReadStreamClientC();

  ReadStream = AdcReadStreamClientC;
  AdcReadStreamClientC.Atm128AdcConfig -> VoltageP;
}
