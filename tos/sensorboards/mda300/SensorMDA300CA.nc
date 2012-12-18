/*
 * Copyright (c) 2012 Sestosenso
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
 * - Neither the name of the Sestosenso nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * SESTOSENSO OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
*  SensorMDA300C brings all the digital and anolog pins to a single component
*  using Read interfaces
*
*  @author Charles Elliott UOIT
*  @modified Feb 27, 2009
*  @modified September 2012 by Franco Di Persio, Sestosenso
*/

generic configuration SensorMDA300CA()
{
  provides
  {   	
   	interface Read<uint16_t> as Vref; //!< voltage
   	
	interface Read<uint16_t> as Temperature; //!< Sht11 Thermister
  	interface Read<uint16_t> as Humidity; //!< Sht11 Humidity sensor
	
	interface Read<uint16_t> as ADC_0; //!< ADC Channel 0 and Comm
	interface Read<uint16_t> as ADC_1; //!< ADC Channel 1 and Comm
	interface Read<uint16_t> as ADC_2; //!< ADC Channel 2 and Comm
	interface Read<uint16_t> as ADC_3; //!< ADC Channel 3 and Comm
	interface Read<uint16_t> as ADC_4; //!< ADC Channel 4 and Comm
	interface Read<uint16_t> as ADC_5; //!< ADC Channel 5 and Comm
	interface Read<uint16_t> as ADC_6; //!< ADC Channel 6 and Comm
	interface Read<uint16_t> as ADC_7; //!< ADC Channel 7 and Comm
	
	interface Read<uint16_t> as ADC_01; //!< ADC Channel 0 and 1
	interface Read<uint16_t> as ADC_23; //!< ADC Channel 2 and 3
	interface Read<uint16_t> as ADC_45; //!< ADC Channel 4 and 5
	interface Read<uint16_t> as ADC_67; //!< ADC Channel 6 and 7
	interface Read<uint16_t> as ADC_10; //!< ADC Channel 1 and 0
	interface Read<uint16_t> as ADC_32; //!< ADC Channel 3 and 2
	interface Read<uint16_t> as ADC_54; //!< ADC Channel 5 and 4
	interface Read<uint16_t> as ADC_76; //!< ADC Channel 7 and 6
	
	interface Read<uint8_t> as Read_DIO; //!< Just read Digital IO
	interface Read<uint8_t> as DIO_0; //!< Int on Digital IO channel 0
	interface Read<uint8_t> as DIO_1; //!< Int on Digital IO channel 1
	interface Read<uint8_t> as DIO_2; //!< Int on Digital IO channel 2
	interface Read<uint8_t> as DIO_3; //!< Int on Digital IO channel 3
	interface Read<uint8_t> as DIO_4; //!< Int on Digital IO channel 4
	interface Read<uint8_t> as DIO_5; //!< Int on Digital IO channel 5
	
	interface Relay as Relay_NC;
	interface Relay	as Relay_NO;
	
	//interface DigOutput as Digital;
	interface Power as Excitacion_25;
	interface Power as Excitacion_33;
	interface Power as Excitacion_50;
	interface SplitControl as ExcitationControl;
	
	interface Notify<bool>;
	
  }
}
implementation
{
    components
    new VoltageC(),
    
    new SensirionSht11C(),
	ADCDeviceC,
	new DIOC(),
	
	HplExcitationC;
    
	//The returned value represents the difference between the battery voltage 
	//and V_BG (1.23V). The formula to convert it to mV is: 1223 * 1024 / value. 
    Vref       = VoltageC;
	
	Temperature = SensirionSht11C.Temperature;
  	Humidity	= SensirionSht11C.Humidity;
	
	ADC_0		= ADCDeviceC.Channel0; //!< ADC Channel 0 and Comm
	ADC_1		= ADCDeviceC.Channel1; //!< ADC Channel 1 and Comm
	ADC_2		= ADCDeviceC.Channel2; //!< ADC Channel 2 and Comm
	ADC_3		= ADCDeviceC.Channel3; //!< ADC Channel 3 and Comm
	ADC_4		= ADCDeviceC.Channel4; //!< ADC Channel 4 and Comm
	ADC_5		= ADCDeviceC.Channel5; //!< ADC Channel 5 and Comm
	ADC_6		= ADCDeviceC.Channel6; //!< ADC Channel 6 and Comm
	ADC_7		= ADCDeviceC.Channel7; //!< ADC Channel 7 and Comm
	
	ADC_01		= ADCDeviceC.Channel01; //!< ADC Channel 0 and 1
	ADC_23		= ADCDeviceC.Channel23; //!< ADC Channel 2 and 3
	ADC_45		= ADCDeviceC.Channel45; //!< ADC Channel 4 and 5
	ADC_67		= ADCDeviceC.Channel67; //!< ADC Channel 6 and 7
	ADC_10		= ADCDeviceC.Channel10; //!< ADC Channel 1 and 0
	ADC_32		= ADCDeviceC.Channel32; //!< ADC Channel 3 and 2
	ADC_54		= ADCDeviceC.Channel54; //!< ADC Channel 5 and 4
	ADC_76		= ADCDeviceC.Channel76; //!< ADC Channel 7 and 6
	
	Read_DIO	= DIOC.Read_DIO; 
	DIO_0	= DIOC.DigChannel_0;
	DIO_1	= DIOC.DigChannel_1;
	DIO_2	= DIOC.DigChannel_2;
	DIO_3	= DIOC.DigChannel_3;
	DIO_4	= DIOC.DigChannel_4;
	DIO_5	= DIOC.DigChannel_5;
	
	Relay_NC = DIOC.Relay_NC;
	Relay_NO = DIOC.Relay_NO;
	
	Notify		= DIOC.Notify; //add to activate the interrupt: May 22, 2012

	Excitacion_25 = HplExcitationC.Excitacion_25;
	Excitacion_33 = HplExcitationC.Excitacion_33;
	Excitacion_50 = HplExcitationC.Excitacion_50;
	ExcitationControl = HplExcitationC.ExcitationControl;
	
}
