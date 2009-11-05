/**
 * Demo sensor for the mica2 platform.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic configuration DemoSensorNowC()
{
  provides interface Resource;
  provides interface ReadNow<uint16_t>;
}
implementation {
  components new AdcReadNowClientC(),
             DemoSensorP,
             HplM16c62pGeneralIOC as IOs,
             RealMainP;

  DemoSensorP.Pin -> IOs.PortP100;
  DemoSensorP.AVcc -> IOs.PortP76;

  ReadNow = AdcReadNowClientC;
  Resource = AdcReadNowClientC;

  AdcReadNowClientC.M16c62pAdcConfig -> DemoSensorP;

  RealMainP.PlatformInit -> DemoSensorP;
}
