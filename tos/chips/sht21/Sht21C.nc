/* Copyright 2010 Unicomp Kft. All rights reserved. Released under BSD license below.


Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY UNICOMP KFT AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of Unicomp Kft.
*/


/*
 * @author Gabor Salamon <gabor.salamon@unicomp.hu>
 */

configuration Sht21C
{
	provides interface Read<uint16_t> as Temperature;
	provides interface Read<uint16_t> as Humidity;
}
implementation
{
	components HplSht21C, RealMainP;
	
	components Sht21HumidLogicP, new TimerMilliC() as TempTimer;;
	Humidity = Sht21HumidLogicP;
	Sht21HumidLogicP.Timer -> TempTimer;
	Sht21HumidLogicP.I2CPacket -> HplSht21C.I2CPacketHumidity;
	Sht21HumidLogicP.I2CResource -> HplSht21C.I2CResourceHumidity;
	Sht21HumidLogicP.BusPowerManager -> HplSht21C;
	Sht21HumidLogicP.Init <- RealMainP.SoftwareInit;
	
	components Sht21TempLogicP, new TimerMilliC() as HumiTimer;
	Temperature = Sht21TempLogicP;
	Sht21TempLogicP.Timer -> HumiTimer;
	Sht21TempLogicP.I2CPacket -> HplSht21C.I2CPacketTemperature;
	Sht21TempLogicP.I2CResource -> HplSht21C.I2CResourceTemperature;
	Sht21TempLogicP.BusPowerManager -> HplSht21C;
	Sht21TempLogicP.Init <- RealMainP.SoftwareInit;
	
}
