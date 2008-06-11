/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
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
 */
/**
 * @author Konrad Lorincz
 * @version 1.0, August 15, 2005
 */
/**
 * @brief Ported to TOS2
 * @author Brano Kusy (branislav.kusy@gmail.com)
 */ 
#ifndef PXA27XQuickCaptInt_H
#define PXA27XQuickCaptInt_H

/******************************************************************************/
// Configure the GPIO Alt functions and directions
// Note:
//  - In Sensor Master-Parallel mode, CIF_FV and CIF_LV are set to INPUTS
//  - In Sensor  Slave-Parallel mode, CIF_FV and CIF_LV are set to OUTPUTS
// Configure the GPIO Alt Functions and Directions
//     --- Template ----
//     _GPIO_setaltfn(PIN, PIN_ALTFN);
//     _GPDR(PIN) &= ~_GPIO_bit(PIN);  // input
//     _GPDR(PIN) |= _GPIO_bit(PIN);   // output
//     -----------------
/******************************************************************************/

// (1) - Define the Pin mappings  (options are listed as <GPIO_PIN#, IN/OUT, ALT_FN#> 
#define PIN_CIF_MCLK            53      // <23,O,1> <42,O,3> <53,O,2>
#define PIN_CIF_MCLK_ALTFN       2
#define PIN_CIF_PCLK            54      // <26,I,2> <45,I,3> <54,I,3>
#define PIN_CIF_PCLK_ALTFN       3
#define PIN_CIF_FV              84      // <24,I,1> <24,O,1> <43,I,3> <43,O,3> <84,I,3> <84,O,3>
#define PIN_CIF_FV_ALTFN         3
#define PIN_CIF_LV              85      // <25,I,1> <25,O,1> <44,I,3> <44,O,3> <85,I,3> <85,O,3>
#define PIN_CIF_LV_ALTFN         3

#define PIN_CIF_DD0              81  //   <27,I,3>    <47,I,1>    <81,I,2>    <98,I,2>
#define PIN_CIF_DD0_ALTFN         2    // SSPEXTCLK   STD_TXD     BB_OB_DAT0  FF_RTS
                                       // CIF_DD0                             KP_DKIN5
                                       // GPIO27_LED_B
#define PIN_CIF_DD1              55  //   <55,I,1>    <105,I,1>   <114*,I,1>
#define PIN_CIF_DD1_ALTFN         1    // BB_IB_DAT1  KP_MKOUT2   CC2420_FIFO
                                       // NPREG                   UVS0

#define PIN_CIF_DD2              51  //   <51,I,1>    <104,I,1>   <116*,I,1>
#define PIN_CIF_DD2_ALTFN         1    // BB_OB_DAT3  KP_MKOUT1   CC2420_CCA
                                       //                         U_DET

#define PIN_CIF_DD3              50  //   <50,I,1>    <103,I,1>   <115*,I,2>
#define PIN_CIF_DD3_ALTFN         1    // BB_OB_DAT2  KP_MKOUT0   CC2420_VREG_EN
                                       // NPIOR                   U_EN

#define PIN_CIF_DD4              52  //   <52,I,1>    <83,I,3>    <90,I,3>    <95,I,2>
#define PIN_CIF_DD4_ALTFN         1    // BB_OB_CLK   BB_IB_CLK   NURST       KP_DKIN2
                                       //                                     GPIO95_LED_R

#define PIN_CIF_DD5              48  //   <48,I,1>    <82,I,3>    <91,I,3>    <94,I,2>
#define PIN_CIF_DD5_ALTFN         1    // BB_OB_DAT1  BB_IB_DAT0  UCLK        KP_DKIN1
                                       //                                     GPIO94_D_CARD

#define PIN_CIF_DD6              17  //   <17,I,2>    <93,I,2>
#define PIN_CIF_DD6_ALTFN         2    // CIF_DD6     KP_DKIN0
                                       // PWM_OUT_1   GPIO93_D_CARD

#define PIN_CIF_DD7              12  //   <12,I,2>    <108,I,1>
#define PIN_CIF_DD7_ALTFN         2    // CIF_DD7     KP_MKOUT5
                                       // 48MHz

//#define PIN_CIF_DD8             107  //   <107,I,1>
//#define PIN_CIF_DD8_ALTFN         1    // CIF_DD8
// KP_MKOUT4
//#define PIN_CIF_DD9             106  //   <106,I,1>
//#define PIN_CIF_DD9_ALTFN         1    // CIF_DD9 

// ===================================================================
#define CIF_CHAN  (11)
#define CIBR0_ADDR  (0x50000028)
#define CICR0_DIS       (1 << 27)	/* Quick Capture Interface Disable */  

#endif
