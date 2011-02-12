#include "ADXL345.h"

generic configuration ADXL345C() {
  provides interface SplitControl;
  provides interface Read<uint16_t> as X;
  provides interface Read<uint16_t> as Y;
  provides interface Read<uint16_t> as Z;
  provides interface Read<uint8_t> as IntSource;
  provides interface Read<uint8_t> as Register;
  provides interface ADXL345Control;
  provides interface Notify<adxlint_state_t> as Int1;
  provides interface Notify<adxlint_state_t> as Int2;
}
implementation {
  components ADXL345P;
  X = ADXL345P.X;
  Y = ADXL345P.Y;
  Z = ADXL345P.Z;
  IntSource = ADXL345P.IntSource;
  SplitControl = ADXL345P;
  ADXL345Control = ADXL345P;
  Register = ADXL345P.Register;

  components new Msp430I2C1C() as I2C;
  ADXL345P.Resource -> I2C;
  ADXL345P.ResourceRequested -> I2C;
  ADXL345P.I2CBasicAddr -> I2C;  

  components HplADXL345C;

  Int1 = ADXL345P.Int1;
  Int2 = ADXL345P.Int2;

  ADXL345P.GpioInterrupt1 ->  HplADXL345C.GpioInterrupt1;
  ADXL345P.GpioInterrupt2 ->  HplADXL345C.GpioInterrupt2;
  ADXL345P.GeneralIO1 -> HplADXL345C.GeneralIO1;
  ADXL345P.GeneralIO2 -> HplADXL345C.GeneralIO2;

  components new TimerMilliC() as TimeoutAlarm;
  ADXL345P.TimeoutAlarm -> TimeoutAlarm;

}
