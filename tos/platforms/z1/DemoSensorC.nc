/** 
 * DemoSensorC is a generic sensor device that provides a 16-bit
 * value. The platform author chooses which sensor actually sits
 * behind DemoSensorC, and though it's probably Voltage, Light, or
 * Temperature, there are no guarantees.
 *
 * This particular DemoSensorC on the z1 platform provides a
 * voltage reading, using BatteryC. 
 *
 *
 * @author Jordi Soucheiron <jsoucheiron@dexmatech.com>
 * @version $Revision: 1.0 $ $Date: 2010/04/28 10:51:45 $
 * 
 */


generic configuration DemoSensorC()
{
  provides interface Read<uint16_t>;
}
implementation
{
  components new BatteryC() as DemoSensor;
  Read = DemoSensor;
}
