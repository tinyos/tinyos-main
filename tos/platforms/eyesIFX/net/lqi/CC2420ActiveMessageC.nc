/* -*- mode:c++; indent-tabs-mode:nil -*- 
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Pseudo module to enable MultihopLqi on eyesIFX. The mapping of
 * strength to LQI is based on the packet delivery ratio.  For CC2420
 * the ratios were taken from: Kannan Srinivasan and Philip Levis:
 * "RSSI is Under Appreciated" Third Workshop on Embedded Networked
 * Sensors, EmNets 2006.
 * 
 * @author Andreas Köpke <koepke@tkn.tu-berlin.de>
 */

#include "radiopacketfunctions.h"

module CC2420ActiveMessageC {
    provides {
        interface CC2420Packet;
    }
}
implementation {
    async command uint8_t CC2420Packet.getPower(message_t* p_msg ) {
        return 31;
    }
    async command void CC2420Packet.setPower(message_t* p_msg, uint8_t power) {
    }
    async command int8_t CC2420Packet.getRssi(message_t* p_msg ) {
        return (getMetadata(p_msg))->strength;
    }
    async command uint8_t CC2420Packet.getLqi( message_t* p_msg ) {
        uint32_t s = (getMetadata(p_msg))->strength;
        if(s > 60) s = 10;
        if(s > 24) s = 24;
        return (s*13/5 + 48);
    }
}
