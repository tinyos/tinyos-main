configuration HplMMA7261QTReaderC
{
  provides interface Read<uint16_t> as AccelX;
  provides interface Read<uint16_t> as AccelY;
  provides interface Read<uint16_t> as AccelZ;
}
implementation
{
  components HplMMA7261QTC;
  
  AccelX = HplMMA7261QTC.AccelX;
  AccelY = HplMMA7261QTC.AccelY;
  AccelZ = HplMMA7261QTC.AccelZ;
}