/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 *
 * - Description ---------------------------------------------------------
 * provide functions to encode/decode a manchester stream
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008-03-05 11:14:00 $
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */

enum {
    ILLEGAL_CODE = 0xff,
    ENCODED_32KHZ_BYTE_TIME = 2*TDA5250_32KHZ_BYTE_TIME
};

const uint8_t nibbleToManchesterByte[] = {
    0x55,
    0x56,
    0x59,
    0x5a,
    0x65,
    0x66,
    0x69,
    0x6a,
    0x95,
    0x96,
    0x99,
    0x9a,
    0xa5,
    0xa6,
    0xa9,
    0xaa
};

const uint8_t manchesterByteToNibble[] = {
    0x0,
    0x1,
    0xff,
    0xff,
    0x2,
    0x3,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0x4,
    0x5,
    0xff,
    0xff,
    0x6,
    0x7,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0x8,
    0x9,
    0xff,
    0xff,
    0xa,
    0xb,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xc,
    0xd,
    0xff,
    0xff,
    0xe,
    0xf
};

uint8_t manchesterEncodeNibble(uint8_t nib) 
{
    return nibbleToManchesterByte[nib];
}

uint8_t manchesterDecodeByte(uint8_t b) 
{
    uint8_t dec;
    
    if(b < 0x55) {
        dec = 0xff;
    }
    else if(b > 0xaa) {
        dec = 0xff;
    }
    else {
        dec = manchesterByteToNibble[b - 0x55];
    }
    return dec;
}
