/* -*- mode:c++; indent-tabs-mode: nil -*- */
/**
 * read interface maxim/dallas 48 bit ID chips
 */
/**
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 */

configuration PlatformOneWireLowLevelC {
    provides interface GeneralIO as OneWirePin;
}
implementation{
  components HplMsp430GeneralIOC;
  components new Msp430GpioC();
  Msp430GpioC.HplGeneralIO -> HplMsp430GeneralIOC.Port24;

  OneWirePin = Msp430GpioC;

  // SDH : this seemed to break with mspgcc4...
  // components PlatformOneWireLowLevelP as Pins;

}
