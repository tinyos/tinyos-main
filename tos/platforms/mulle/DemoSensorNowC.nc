/**
 * Demo sensor for the Mulle platform.
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
             HplM16c60GeneralIOC as IOs,
             RealMainP;

  DemoSensorP.Pin -> IOs.PortP100;
  DemoSensorP.AVcc -> IOs.PortP76;

  ReadNow = AdcReadNowClientC;
  Resource = AdcReadNowClientC;

  AdcReadNowClientC.M16c60AdcConfig -> DemoSensorP;

  RealMainP.PlatformInit -> DemoSensorP;
}
