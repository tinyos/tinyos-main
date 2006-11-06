/**
 * The default sensor for MViz is a simple sine wave.
 *
 * @author Philip Levis
 */

generic configuration MVizSensorC()
{
  provides interface Read<uint16_t>;
}
implementation
{
  components new SineSensorC() as DemoChannel;

  Read = DemoChannel;
}
