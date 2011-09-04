generic component DemoSensorStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components new InternalTempStreamC() as Stream;

  ReadSteam = Stream; 
}
