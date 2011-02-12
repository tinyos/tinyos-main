generic configuration BatteryC() {
 provides interface DeviceMetadata;
 provides interface Read<uint16_t>;
 provides interface ReadStream<uint16_t>;
}
implementation {
 components new AdcReadClientC();
 Read = AdcReadClientC;

 components new AdcReadStreamClientC();
 ReadStream = AdcReadStreamClientC;

 components BatteryP;
 DeviceMetadata = BatteryP;
 AdcReadClientC.AdcConfigure -> BatteryP;
 AdcReadStreamClientC.AdcConfigure -> BatteryP;
}
