
configuration BMP085C {
  provides {
    interface Read<uint16_t> as Pressure;
    interface SplitControl as BMPSwitch;
  }

}
implementation {

  components BMP085P;
  Pressure = BMP085P.Pressure;
  BMPSwitch = BMP085P.BMPSwitch;
 
  components new Msp430I2C1C() as I2C;
  BMP085P.Resource -> I2C;
  BMP085P.ResourceRequested -> I2C;
  BMP085P.I2CBasicAddr -> I2C; 

  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as XCLR;
  XCLR -> GeneralIOC.Port42; 
  BMP085P.Reset -> XCLR;

  components new TimerMilliC() as TimeoutTimer;
  BMP085P.TimeoutTimer -> TimeoutTimer;

}
