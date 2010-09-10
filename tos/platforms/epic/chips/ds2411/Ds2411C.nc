/* -*- mode:c++; indent-tabs-mode: nil -*- */
/**
 * DS2411 tmote sky serial id
 */
/**
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 */

#include "Timer.h"

configuration Ds2411C {
    provides interface ReadId48;
}
implementation {
    components
        Ds2411P,
        PlatformOneWireLowLevelC,
        OneWireMasterC;
    
    ReadId48 = Ds2411P;
    Ds2411P.OneWire -> OneWireMasterC;
    OneWireMasterC.Pin -> PlatformOneWireLowLevelC;
}
