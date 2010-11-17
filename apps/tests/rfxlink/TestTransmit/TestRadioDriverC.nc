/*
 * Copyright (c) 2010, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

configuration TestRadioDriverC
{
}

implementation
{
	components TestRadioDriverP, MainC, SerialActiveMessageC, AssertC, LedsC, RadioAlarmC;
	
	TestRadioDriverP.Boot -> MainC;
	TestRadioDriverP.SplitControl -> SerialActiveMessageC;
	TestRadioDriverP.RadioState -> RadioDriverLayerC;
	TestRadioDriverP.RadioSend -> RadioDriverLayerC;
	TestRadioDriverP.RadioPacket -> TimeStampingLayerC;
	TestRadioDriverP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	TestRadioDriverP.Leds -> LedsC;

	// just to avoid a timer compilation bug
	components new TimerMilliC();

// -------- TimeStamping

	components TimeStampingLayerC;
	TimeStampingLayerC.LocalTimeRadio -> RadioDriverLayerC;
	TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;

// -------- MetadataFlags

	components MetadataFlagsLayerC;
	MetadataFlagsLayerC.SubPacket -> RadioDriverLayerC;

// -------- RadioDriver

#if defined(PLATFORM_IRIS) || defined(PLATFORM_MULLE)
	components RF230DriverLayerC as RadioDriverLayerC;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSA) || defined(PLATFORM_TELOSB)
	components CC2420XDriverLayerC as RadioDriverLayerC;
#endif

	RadioDriverLayerC.Config -> TestRadioDriverP;
	RadioDriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
}
