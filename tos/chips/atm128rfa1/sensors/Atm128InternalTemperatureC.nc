/**
  * Atmega128rfa1 internal temperature sensor.
  *
  * @author Zsolt Szabo <szabomeister@gmail.com>
  */

generic configuration Atm128InternalTemperatureC() {
  provides interface Read<uint16_t>;
  //provides interface ReadStream<uint16_t>;
}
implementation {
  components  ArbitratedInternalTempDeviceP; //Atm128InternalTempDeviceP;
  
  Read = ArbitratedInternalTempDeviceP.Read[unique("InternalTemp.resource")]; //Atm128InternalTempDeviceP.Read;
}
