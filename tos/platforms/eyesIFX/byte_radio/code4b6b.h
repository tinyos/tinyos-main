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
 */

/**
 * provide functions to encode/decode a 4b 6b stream
 * @author Andreas Koepke <koepke@tkn.tu-berlin.de>
 * Book:     RF Monolithics, Inc: ASH Transceiver Designer's Guide, Okt 2002.
 * http://www.rfm.com/products/tr_des24.pdf
 */

#ifndef CODE_4B_6B_H
#define CODE_4B_6B_H

enum {
    ILLEGAL_CODE = 0xff,
    ENCODED_32KHZ_BYTE_TIME = 3*TDA5250_32KHZ_BYTE_TIME/2
};

const uint8_t nibbleToSixBit[] = {
    13, // 001101
    14, // 001110
    19, // 010011
    21, // 010101
    22, // 010110
    25, // 011001
    26, // 011010
    28, // 011100
    35, // 100011
    37, // 100101
    38, // 100110
    41, // 101001
    42, // 101010
    44, // 101100
    50, // 110010
    52  // 110100
};

const uint8_t sixBitToNibble[] = {
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    0x00,
    0x01,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    0x02,
    ILLEGAL_CODE,
    0x03,
    0x04,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    0x05,
    0x06,
    ILLEGAL_CODE,
    0x07,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    0x08,
    ILLEGAL_CODE,
    0x09,
    0x0a,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    0x0b,
    0x0c,
    ILLEGAL_CODE,
    0x0d,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    0x0e,
    ILLEGAL_CODE,
    0x0f,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE,
    ILLEGAL_CODE
};

#endif
