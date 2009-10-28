/**
 * The DS2745 works well to be used with the DS2782 chip on the Mulle.
 * 
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

// TODO(henrik) Clean and comment this code better. Also Make the chip request
//              access to the I2C bus instead of how its now that the program
//              needs to request it.
configuration DS2745InternalC {
  provides interface SplitControl;
  provides interface Resource;
  provides interface HplDS2745;
}

implementation {
  components MainC;
  
  components new SoftI2CBatteryMonitorRTCC() as I2C;
  Resource = I2C;
  
  components new HplDS2745LogicP(0x68) as Logic;
  MainC.SoftwareInit -> Logic;
  Logic.I2CPacket -> I2C;
  HplDS2745 = Logic;

  SplitControl = Logic;

}
