/*
 * Copyright (c) 2007 Matus Harvan
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "IP.h"
#include "IP_internal.h"
#include "message.h"

#ifdef ENABLE_PRINTF_DEBUG
#include "printf.h"
#endif /* ENABLE_PRINTF_DEBUG */

configuration IPC {
    provides {
	interface SplitControl as IPControl;
	interface IP;
	interface UDPClient[uint8_t i];
    }
}
 
implementation { 
    components IPP;
    components ActiveMessageC as AM;
    //TODO: need at least 2 pkts for ND
    components new PoolC(lowpan_pkt_t, SEND_PKTS) as SendPktPool;
    components new PoolC(app_data_t, FRAG_BUFS) as AppDataPool;
    components new PoolC(frag_info_t, FRAG_BUFS*FRAGS_PER_DATAGRAM)
	as FragInfoPool;
    components new TimerMilliC() as Timer;
    components LedsC;
    
    IPControl = IPP;
    UDPClient = IPP.UDPClient;
    IP = IPP.IP;

    IPP.MessageControl -> AM;
    IPP.Receive -> AM.Receive[AM_IP_MSG];
    IPP.AMSend -> AM.AMSend[AM_IP_MSG];
    IPP.Packet -> AM;
    IPP.AMPacket -> AM;

    IPP.SendPktPool -> SendPktPool;
    IPP.AppDataPool -> AppDataPool;
    IPP.FragInfoPool -> FragInfoPool;

    IPP.Leds -> LedsC;
    IPP.Timer -> Timer;

#ifdef ENABLE_PRINTF_DEBUG
    components PrintfC;
    IPP.PrintfControl -> PrintfC;
    IPP.PrintfFlush -> PrintfC;
#endif /* ENABLE_PRINTF_DEBUG */
}

