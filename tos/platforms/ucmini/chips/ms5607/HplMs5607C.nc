configuration HplMs5607C {
  provides interface I2CPacket<TI2CBasicAddr> ;
  provides interface Resource;
}
implementation {
  
  components new Atm128I2CMasterC() as I2CBus;
  
  I2CPacket = I2CBus.I2CPacket;
  Resource  = I2CBus.Resource;
}
