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
 * wires to VCC.
 * 
 * @author Danny Park
 */
 
configuration Adg715PowerC {
	provides {
    
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
	}
}
implementation {
	components new HplAdg715C(FALSE, FALSE);
	ChannelLightPower    = HplAdg715C.Channel1;
	Channel2PowerNull    = HplAdg715C.Channel2;
	ChannelPressurePower = HplAdg715C.Channel3;
	ChannelHumidityPower = HplAdg715C.Channel4;
	ChannelEepromPower   = HplAdg715C.Channel5;
	ChannelAccelPower    = HplAdg715C.Channel6;
	DcDcBoost33Channel  = HplAdg715C.Channel7;
//	ChannelGpsEnable     = HplAdg715C.Channel8;
	DcDcBoost5Channel   = HplAdg715C.Channel8;
//	ChannelGpsPower      = HplAdg715C.Channel7;
}
