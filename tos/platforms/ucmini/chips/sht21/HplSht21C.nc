configuration HplSht21C
{
	provides interface I2CPacket<TI2CBasicAddr> as I2CPacketHumidity;
	provides interface Resource as I2CResourceHumidity;
	
	provides interface I2CPacket<TI2CBasicAddr> as I2CPacketTemperature;
	provides interface Resource as I2CResourceTemperature;
	
	provides interface BusPowerManager;
}
implementation
{
	components I2CBusPowerManagerC;
	BusPowerManager = I2CBusPowerManagerC;
	
	components new Atm128I2CMasterC() as I2CHumi;
	
	I2CPacketHumidity = I2CHumi;
	I2CResourceHumidity = I2CHumi;
	
	components new Atm128I2CMasterC() as I2CTemp;
	I2CPacketTemperature = I2CTemp;
	I2CResourceTemperature = I2CTemp;
}
