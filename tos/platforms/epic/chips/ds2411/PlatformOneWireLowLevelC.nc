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
    components PlatformOneWireLowLevelP as Pins;
    OneWirePin = Pins;
}
