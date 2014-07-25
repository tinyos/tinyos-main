/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai, Miklos Maroti
 */

#include <RadioConfig.h>
#include <CC2420XDriverLayer.h>

configuration CC2420XDriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface Alarm<TRadio, tradio_size>;
	}

	uses
	{
		interface CC2420XDriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;
		interface RadioAlarm;
		interface Tasklet;
	}
}

implementation
{
	components CC2420XDriverLayerP as DriverLayerP,
		BusyWaitMicroC,
		MainC,
		HplCC2420XC as HplC;

	MainC.SoftwareInit -> DriverLayerP.SoftwareInit;
	MainC.SoftwareInit -> HplC.Init;

	RadioState = DriverLayerP;
	RadioSend = DriverLayerP;
	RadioReceive = DriverLayerP;
	RadioCCA = DriverLayerP;
	RadioPacket = DriverLayerP;

	LocalTimeRadio = HplC;
	Config = DriverLayerP;

	DriverLayerP.VREN -> HplC.VREN;
	DriverLayerP.CSN -> HplC.CSN;
	DriverLayerP.CCA -> HplC.CCA;
	DriverLayerP.RSTN -> HplC.RSTN;
	DriverLayerP.FIFO -> HplC.FIFO;
	DriverLayerP.FIFOP -> HplC.FIFOP;
	DriverLayerP.SFD -> HplC.SFD;

	PacketTransmitPower = DriverLayerP.PacketTransmitPower;
	TransmitPowerFlag = DriverLayerP.TransmitPowerFlag;

	PacketRSSI = DriverLayerP.PacketRSSI;
	RSSIFlag = DriverLayerP.RSSIFlag;

	PacketTimeSyncOffset = DriverLayerP.PacketTimeSyncOffset;
	TimeSyncFlag = DriverLayerP.TimeSyncFlag;

	PacketLinkQuality = DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = DriverLayerP.PacketTimeStamp;
	LinkPacketMetadata = DriverLayerP;

	Alarm = HplC.Alarm;
	RadioAlarm = DriverLayerP.RadioAlarm;

	DriverLayerP.SpiResource -> HplC.SpiResource;
	DriverLayerP.FastSpiByte -> HplC;

	DriverLayerP.SfdCapture -> HplC;
	DriverLayerP.FifopInterrupt -> HplC;

	Tasklet = DriverLayerP.Tasklet;
	DriverLayerP.BusyWait -> BusyWaitMicroC;

	DriverLayerP.LocalTime-> HplC.LocalTimeRadio;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	DriverLayerP.DiagMsg -> DiagMsgC;
#endif

#ifdef PPPSNIFFER
	/* Serial stack */
	components PppDaemonC;
	DriverLayerP.PppSplitControl -> PppDaemonC;

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_EPIC)
	components PlatformHdlcUartC as HdlcUartC;
#else
	components DefaultHdlcUartC as HdlcUartC;
#endif
	PppDaemonC.HdlcUart -> HdlcUartC;
	PppDaemonC.UartControl -> HdlcUartC;

	/* Link in RFC5072 support for both the control and network protocols */
	components PppIpv6C;
	PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
	PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
	PppIpv6C.Ppp -> PppDaemonC;
	PppIpv6C.LowerLcpAutomaton -> PppDaemonC;
	DriverLayerP.Ipv6LcpAutomaton -> PppIpv6C;
	DriverLayerP.PppIpv6 -> PppIpv6C;
#endif

	components LedsC;
	DriverLayerP.Leds -> LedsC;
}
