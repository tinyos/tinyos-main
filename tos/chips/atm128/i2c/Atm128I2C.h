// $Id: Atm128I2C.h,v 1.5 2009-03-13 19:15:35 idgay Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
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
