/**
  *
  * @author Zsolt Szabó <szabomeister@gmail.com>
  */

generic configuration DemoSensorC() {
  //provides interface Read<uint32_t>;
  provides interface Read<uint16_t>;
  provides interface SplitControl;
}
implementation {
  //components new Atm128InternalTemperatureC() as Sensor;
  //Read = Sensor;
  components Sht21C as Sensor;
  Read = Sensor.Temperature;
  //Read = Sensor.Humidity;

  components I2CBusC;
  SplitControl = I2CBusC.BusControl;

  //components bh1750fviC as Sensor;
  //Read = Sensor.Light;

  //components ms5607C as Sensor;
  //Read = Sensor.Pressure;
}
