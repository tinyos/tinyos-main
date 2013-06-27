/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * Copyright (c) 2002-2003 Intel Corporation
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * The TinyOS 2.x PPPSniffer snoops AM and bare 802.15.4 packets and
 * delivers them over ppp to the host computer. On the host wireshark
 * can pick the packets up on the ppp interface.
 *
 * @author Markus Becker
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * @author David Gay
 * @author Philip Levis
 * @date January 3 2011
 */
//#include "ppp.h"
#include <Ieee154.h>

configuration PPPSnifferC {
}
implementation {

    /*
#define UQ_METADATA_FLAGS       "UQ_METADATA_FLAGS"
#define UQ_RADIO_ALARM          "UQ_RADIO_ALARM"
    */
    components MainC, PPPSnifferP, LedsC;//, AssertC;

    PPPSnifferP.Boot -> MainC;
    /*
    PPPSnifferP.Leds -> LedsC;
    */
    //PPPSnifferP.SplitControl -> SerialActiveMessageC;
    components ActiveMessageC as MessageC;
    PPPSnifferP.MessageControl -> MessageC;
    PPPSnifferP.Packet -> MessageC.Packet;
    //PPPSnifferP.Receive -> MessageC.Receive;

    /* Serial stack */
    /*
    components PppDaemonC;
    PPPSnifferP.PppSplitControl -> PppDaemonC;

    components PlatformSerialHdlcUartC;
    PppDaemonC.HdlcUart -> PlatformSerialHdlcUartC;
    PppDaemonC.UartControl -> PlatformSerialHdlcUartC;
    */
    /* Link in RFC5072 support for both the control and network protocols */
    /*
    components PppIpv6C;
    PppDaemonC.PppProtocol[PppIpv6C.ControlProtocol] -> PppIpv6C.PppControlProtocol;
    PppDaemonC.PppProtocol[PppIpv6C.Protocol] -> PppIpv6C.PppProtocol;
    PppIpv6C.Ppp -> PppDaemonC;
    PppIpv6C.LowerLcpAutomaton -> PppDaemonC;
    PPPSnifferP.Ipv6LcpAutomaton -> PppIpv6C;
    PPPSnifferP.PppIpv6 -> PppIpv6C;
    */
    /* Link in the custom protocol for printf support */
    /*
    components PppPrintfC;
    PppPrintfC.Ppp -> PppDaemonC;
    PppDaemonC.PppProtocol[PppPrintfC.Protocol] -> PppPrintfC;
    */
}
