/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:31:15 $
 * ========================================================================
 */

 /**
 * tda5250RegTypes Header File
 * Defines the register types for the registers on the TDA5250 Radio
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

#ifndef TDA5250REGTYPES_H
#define TDA5250REGTYPES_H

//Macro for receiving an address and figuring out its type
#define TDA5250_REG_TYPE(addr) TDA5250_REG_TYPE_#addr

// Default values of data registers
#define TDA5250_REG_TYPE_CONFIG           uint16_t
#define TDA5250_REG_TYPE_FSK              uint16_t
#define TDA5250_REG_TYPE_XTAL_TUNING      uint16_t
#define TDA5250_REG_TYPE_LPF              uint8_t
#define TDA5250_REG_TYPE_ON_TIME          uint16_t
#define TDA5250_REG_TYPE_OFF_TIME         uint16_t
#define TDA5250_REG_TYPE_COUNT_TH1        uint16_t
#define TDA5250_REG_TYPE_COUNT_TH2        uint16_t
#define TDA5250_REG_TYPE_RSSI_TH3         uint8_t
#define TDA5250_REG_TYPE_RF_POWER         uint8_t
#define TDA5250_REG_TYPE_CLK_DIV          uint8_t
#define TDA5250_REG_TYPE_XTAL_CONFIG      uint8_t
#define TDA5250_REG_TYPE_BLOCK_PD         uint16_t
#define TDA5250_REG_TYPE_STATUS           uint8_t
#define TDA5250_REG_TYPE_ADC              uint8_t

#endif //TDA5250REGTYPES_H

