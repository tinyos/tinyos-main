/*
 *
 *
 * Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 *
 */
/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:  Lama Nachman, Robbie Adler
 *
 * This file includes the PMIC command defintions.  We are using the Dialog
 * DA9030 part. 
 *
 */

#ifndef PMIC_H
#define PMIC_H

// I2C slave addr
#define PMIC_SLAVE_ADDR 0x49

// Register BUCK2 with DVC1
#define PMIC_BUCK2_REG1 0x15

// Register BUCK2 with DVC2
#define PMIC_BUCK2_REG2 0x16

// LDO on/off control in App Reg space
#define PMIC_A_REG_CONTROL_1 0x17
#define PMIC_A_REG_CONTROL_2 0x18

#define PMIC_EVENTS                 (0x01)	// 3 byte array
#define PMIC_EVENTA                 (0x01)
#define PMIC_EVENTB                 (0x02)
#define PMIC_EVENTC                 (0x03)
#define PMIC_STATUS                 (0x04)
#define PMIC_IRQ_MASK_A             (0x05)
#define PMIC_IRQ_MASK_B             (0x06)
#define PMIC_IRQ_MASK_C             (0x07)
#define PMIC_SYS_CONTROL_A          (0x08)
#define PMIC_SYS_CONTROL_C          (0x80)

#define PMIC_CHARGE_CONTROL         (0x28)
#define PMIC_CC_CHARGE_ENABLE       (1<<7)
#define PMIC_CC_ISET(_x)            (((_x) & 0xF) << 3)
#define PMIC_CC_VSET(_x)            (((_x) & 0x7))

#define PMIC_TCTR_CONTROL           (0x2A)

#define PMIC_ADC_MAN_CONTROL        (0x30)
#define PMIC_AMC_ADCMUX(_x)         ((_x & 0x7))
#define PMIC_AMC_MAN_CONV           (1<<3)
#define PMIC_AMC_LDO_INT_Enable     (1<<4)

#define PMIC_MAN_RES                (0x40)
#define PMIC_LED1_CONTROL           (0x20)

// LDO on/off control in Baseband Reg space
#define PMIC_B_REG_CONTROL_1 0x97
#define PMIC_B_REG_CONTROL_2 0x98
#define PMIC_B_SLEEP_CONTROL_1 0x99
#define PMIC_B_SLEEP_CONTROL_2 0x9A
#define PMIC_B_SLEEP_CONTROL_3 0x9B

// IRQ_MASK_A
#define IMA_ONKEY_N 0x1
#define IMA_PWREN1 0x2
#define IMA_EXTON 0x4
#define IMA_CHDET 0x8
#define IMA_TBAT 0x10
#define IMA_VBATMON_1 0x20
#define IMA_VBATMON_2 0x40
#define IMA_CHIOVER 0x80
 
//IRQ_MASK_B
#define IMB_TCTO 0x1
#define IMB_CCTO 0x2
#define IMB_ADC_READY 0x4
#define IMB_VBUS_VALID_4_4 0x8
#define IMB_VBUS_VALID_4_0 0x10
#define IMB_SESSION_VALID 0x20
#define IMB_SRP_DETECT 0x40
#define IMB_WDOG 0x80

// SYS_CONTROL_A
#define SCA_SLEEP_N_EN 0x1
#define SCA_SHUTDOWN 0x2
#define SCA_HWRES_EN 0x4
#define SCA_WDOG_ACTION 0x8
#define SCA_TWDSCALE(_x) (((_x) & 7) << 4)
#define SCA_RESET_WDOG 0x80

// Events registers A, B, C
#define EVENTS_A_OFFSET 0
#define EA_ONKEY_N 0x1
#define EA_PWREN1 0x2
#define EA_EXTON 0x4
#define EA_CHDET 0x8
#define EA_TBAT 0x10
#define EA_VBATMON 0x20
#define EA_VBATMON_TXON 0x40
#define EA_CHIOVER 0x80

#define EVENTS_B_OFFSET 1
#define EVENTS_C_OFFSET 2

// BUCK2 Reg 1
#define B2R1_TRIM_MASK 0x1f
#define B2R1_TRIM_P85_V 0x0
#define B2R1_TRIM_P875_V 0x1
#define B2R1_TRIM_P9_V 0x2
#define B2R1_TRIM_P925_V 0x3
#define B2R1_TRIM_P95_V 0x4
#define B2R1_TRIM_P975_V 0x5
#define B2R1_TRIM_1_V 0x6
#define B2R1_TRIM_1_125_V 0xB
#define B2R1_TRIM_1_25_V 0x10
#define B2R1_SLEEP 0x40
#define B2R1_GO 0x80

// Reg Control 1 for App processor reg space: Enable/Disable LDOs
#define ARC1_BUCK2_EN 0x1	// on
#define ARC1_LDO10_EN 0x2	// off
#define ARC1_LDO11_EN 0x4	// off
#define ARC1_LDO13_EN 0x8	// off
#define ARC1_LDO14_EN 0x10	// off
#define ARC1_LDO15_EN 0x20	// on
#define ARC1_LDO16_EN 0x40	// on
#define ARC1_LDO17_EN 0x80	// off

// Reg Control 2 for App processor reg space : Enable/Disable LDOs
#define ARC2_LDO18_EN 0x1	// on
#define ARC2_LDO19_EN 0x2	// on
#define ARC2_SIMCP_EN 0x40	// off

// Reg Control 1 for Baseband reg space
#define BRC1_BUCK_EN 0x1	// off
#define BRC1_LDO1_EN 0x2	// off
#define BRC1_LDO2_EN 0x4	// off
#define BRC1_LDO3_EN 0x8	// BB
#define BRC1_LDO4_EN 0x10	// off
#define BRC1_LDO5_EN 0x20	// radio
#define BRC1_LDO6_EN 0x40	// off
#define BRC1_LDO7_EN 0x80	// off

// Reg Control 2 for Baseband reg space
#define BRC2_LDO8_EN 0x1	// off
#define BRC2_LDO9_EN 0x2	// off
#define BRC2_LDO10_EN 0x4	// sensor board
#define BRC2_LDO11_EN 0x8	// sensor board
#define BRC2_LDO12_EN 0x10	// BB_IO
#define BRC2_LDO14_EN 0x20	// off
#define BRC2_SIMCP_EN 0x40	// off
#define BRC2_SLEEP 0x80	 	// off

// Sleep control 1 for Baseband reg space
#define BSC1_LDO1(_x)            (((_x) & 0x3) << 0)
#define BSC1_LDO2(_x)            (((_x) & 0x3) << 2)
#define BSC1_LDO3(_x)            (((_x) & 0x3) << 4)
#define BSC1_LDO4(_x)            (((_x) & 0x3) << 6)

// Sleep control 2 for Baseband reg space
#define BSC2_LDO5(_x)            (((_x) & 0x3) << 0)
#define BSC2_LDO7(_x)            (((_x) & 0x3) << 2)
#define BSC2_LDO8(_x)            (((_x) & 0x3) << 4)
#define BSC2_LDO9(_x)            (((_x) & 0x3) << 6)

// Sleep control 3 for Baseband reg space
#define BSC3_LDO12(_x)            (((_x) & 0x3) << 0)

#endif //PMIC_H
