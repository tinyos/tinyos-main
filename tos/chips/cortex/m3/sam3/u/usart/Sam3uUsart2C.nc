configuration Sam3uUsart2C {
  provides interface Sam3uUsart;
}
implementation{
  components Sam3uUsart2P, HplSam3uUsart2C;
  Sam3uUsart = Sam3uUsart2P;
  Sam3uUsart2P.HplUsart -> HplSam3uUsart2C;

  components LedsC;
  Sam3uUsart2P.Leds -> LedsC;
}