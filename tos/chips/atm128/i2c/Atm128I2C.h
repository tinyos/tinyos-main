// $Id: Atm128I2C.h,v 1.6 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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

// @author Martin Turon <mturon@xbow.com>

#ifndef _H_Atm128I2C_h
#define _H_Atm128I2C_h

#define ATM128_I2C_SLA_WRITE 0x00
#define ATM128_I2C_SLA_READ 0x01

#define UQ_ATM128_I2CMASTER "Atm128I2CMasterC.I2CPacket"

enum {
    ATM128_I2C_BUSERROR         = 0x00,
    ATM128_I2C_START            = 0x08,
    ATM128_I2C_RSTART           = 0x10,
    ATM128_I2C_MW_SLA_ACK       = 0x18,
    ATM128_I2C_MW_SLA_NACK      = 0x20,
    ATM128_I2C_MW_DATA_ACK      = 0x28,
    ATM128_I2C_MW_DATA_NACK     = 0x30,
    ATM128_I2C_M_ARB_LOST       = 0x38,
    ATM128_I2C_MR_SLA_ACK       = 0x40,
    ATM128_I2C_MR_SLA_NACK      = 0x48,
    ATM128_I2C_MR_DATA_ACK      = 0x50,
    ATM128_I2C_MR_DATA_NACK     = 0x58
};

#ifndef ATM128_I2C_EXTERNAL_PULLDOWN
#define ATM128_I2C_EXTERNAL_PULLDOWN FALSE
#endif

#endif // _H_Atm128I2C_h
