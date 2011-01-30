configuration Sam3uUsart1C {
  provides interface Sam3uUsart;
}
implementation{
  components Sam3uUsart1P, HplSam3uUsart1C;
  Sam3uUsart = Sam3uUsart1P;
  Sam3uUsart1P.HplUsart -> HplSam3uUsart1C;

  components LedsC;
  Sam3uUsart1P.Leds -> LedsC;
}