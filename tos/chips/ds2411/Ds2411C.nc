/* Driver for the DS2411 unique ID chip.
 *
 * @author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration Ds2411C {
  provides interface ReadId48;
}
implementation {
  components Ds2411P;
  components OneWireMasterC;
  components HplDs2411C;
  components Ds2411PowerControlC;

  Ds2411P.OneWire -> OneWireMasterC.OneWire;
  Ds2411P.PowerControl -> Ds2411PowerControlC.StdControl;
  OneWireMasterC.Pin -> HplDs2411C.Gpio;

  ReadId48 = Ds2411P.ReadId48;
}
