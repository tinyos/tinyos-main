configuration Sam3uUsart0C {
  provides interface Sam3uUsart;
}
implementation{
  components Sam3uUsart0P, HplSam3uUsart0C;
  Sam3uUsart = Sam3uUsart0P;
  Sam3uUsart0P.HplUsart -> HplSam3uUsart0C;

  components LedsC;
  Sam3uUsart0P.Leds -> LedsC;
}