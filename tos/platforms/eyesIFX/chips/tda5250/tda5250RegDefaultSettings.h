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
 * $Date: 2006-11-07 19:31:23 $
 * ========================================================================
 */

 /**
 * tda5250RegDefaultSettings Header File
 * Defines the default values of the registers for the TDA5250 Radio
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

#ifndef TDA5250REGDEFAULTSETTINGS_H
#define TDA5250REGDEFAULTSETTINGS_H

// Default values of data registers

#define TDA5250_REG_DEFAULT_SETTING_CONFIG           0x84F9 
#define TDA5250_REG_DEFAULT_SETTING_FSK              0x0A0C
#define TDA5250_REG_DEFAULT_SETTING_XTAL_TUNING      0x0012
#define TDA5250_REG_DEFAULT_SETTING_LPF              0x6A
#define TDA5250_REG_DEFAULT_SETTING_ON_TIME          0xFEC0
#define TDA5250_REG_DEFAULT_SETTING_OFF_TIME         0xF380
#define TDA5250_REG_DEFAULT_SETTING_COUNT_TH1        0x0000
#define TDA5250_REG_DEFAULT_SETTING_COUNT_TH2        0x0001
#define TDA5250_REG_DEFAULT_SETTING_RSSI_TH3         0xFF
#define TDA5250_REG_DEFAULT_SETTING_CLK_DIV          0x08
#define TDA5250_REG_DEFAULT_SETTING_XTAL_CONFIG      0x01
#define TDA5250_REG_DEFAULT_SETTING_BLOCK_PD         0xFFFF

#endif //TDA5250REGDEFAULTSETTINGS_H

