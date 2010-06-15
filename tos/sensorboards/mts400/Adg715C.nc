/*
 * Copyright (c) 2008 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * The adg715 chip has 8 channels that are controlled through the I2C
 * bus.  This configuration provides 8 Channel interfaces corresponding
 * to the 8 physical channels on the chip.  This implementation is
 * specific to the mts420CA sensorboard and the adg715 that connects
 * the communication wires.
 * 
 * @author Danny Park
 */
 
#include"Adg715.h" 
 
configuration Adg715C {
	provides {
		/** Connects UART_TXD to GPS_RX */
		//interface Channel as ChannelGpsRx;

		/** Connects Accel_X to ADC1 */
		interface Channel as ChannelAccel_X;

		/** Connects UART_RXD to GPS_TX */
		//interface Channel as ChannelGpsTx;

		/** Connects Accel_Y to ADC2  */
		interface Channel as ChannelAccel_Y;

		/** Connects UART_CLK to Pressure_SCLK */
		/** Connects Pressure_SCLK to FLASH_CLK*/
		interface Channel as ChannelPressureClock;

		/** Connects UART_TX to Pressure_DOUT */
		/** Connects Pressure_DIN to FLASH_SI  */
		interface Channel as ChannelPressureDin;

		/** Connects UART_RX to Pressure_DIN */
		/** Connects Pressure_DOUT to FLASH_SO */
		interface Channel as ChannelPressureDout;

		/** Pins not connected for channel 6 on this chip */
		//interface Channel as Channel6CommNull;

		/** Connects Thermopile_Select_Cnt to GND */    
		interface Channel as ChannelThermopile_Select_Cnt;

		/** Connects PW3 to Humidity_SCK */
		interface Channel as ChannelHumidityClock;

		/** Connects INT3 to Humidity_DATA */
		interface Channel as ChannelHumidityData;
		
		/** Connects VCC to Light_Power */
		interface Channel as ChannelLightPower;
    
		/** Pins not connected for channel 2 on this chip  */
		interface Channel as Channel2PowerNull;
    
		/** Connects VCC to Pressure_Power */
		interface Channel as ChannelPressurePower;
    
		/** Connects VCC to Humidity_Power */
		interface Channel as ChannelHumidityPower;
	
		/** Connects VCC to EEPROM_Power */
		interface Channel as ChannelEepromPower;
    
		/** Connects VCC to Accel_Power */
		interface Channel as ChannelAccelPower;
    
		/** Connect 33VDCDCBOOST to GND (switch on)*/
		interface Channel as DcDcBoost33Channel;
		/** Connects VCC to GPS_PWR */
		//interface Channel as ChannelGpsPower;
	
		/** Connect 5VDCDCBOOST_SHUTDOWN to GND (switch on)*/
		interface Channel as DcDcBoost5Channel;
		/** Connects VCC to GPS_ENA */
		//interface Channel as ChannelGpsEnable;
	
		interface Resource[ uint8_t id ];
	}
}
implementation {
	components new FcfsArbiterC( UQ_ADG715 );
	Resource = FcfsArbiterC;
	components new HplAdg715C(FALSE, TRUE) as Comm;
	ChannelAccel_X       = Comm.Channel1;
	ChannelAccel_Y       = Comm.Channel2;
	ChannelPressureClock = Comm.Channel3;
	ChannelPressureDin   = Comm.Channel4;
	ChannelPressureDout  = Comm.Channel5;
//	Channel6CommNull     = Comm.Channel6;
	ChannelThermopile_Select_Cnt = Comm.Channel6;
	ChannelHumidityClock = Comm.Channel7;
	ChannelHumidityData  = Comm.Channel8;
	components new HplAdg715C(FALSE, FALSE) as Power;
	ChannelLightPower    = Power.Channel1;
	Channel2PowerNull    = Power.Channel2;
	ChannelPressurePower = Power.Channel3;
	ChannelHumidityPower = Power.Channel4;
	ChannelEepromPower   = Power.Channel5;
	ChannelAccelPower    = Power.Channel6;
	DcDcBoost33Channel  = Power.Channel7;
//	ChannelGpsEnable     = Power.Channel8;
	DcDcBoost5Channel   = Power.Channel8;
//	ChannelGpsPower      = Power.Channel7;
}
