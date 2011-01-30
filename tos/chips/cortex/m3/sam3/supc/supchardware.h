/**
 * Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Supply Controller register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef SUPCHARDWARE_H
#define SUPCHARDWARE_H

/**
 * SUPC Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 291
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0  :  2;
        uint8_t vroff      :  1; // voltage regulator off (1: stop regularot if key correct)
        uint8_t xtalsel    :  1; // crystal oscillator select (1: select crystal if key correct)
        uint8_t reserved1  :  4;
        uint16_t reserved2 : 16;
        uint8_t key        :  8; // key shoulc be written to value 0xA5
    } __attribute__((__packed__)) bits;
} supc_cr_t;

#define SUPC_CR_KEY 0xA5

/**
 * SUPC Supply Monitor Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 292
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t smth      :  4; // supply monitor threshold
        uint8_t reserved0 :  4;
        uint8_t smsmpl    :  3; // supply monitor sampling period
        uint8_t reserved1 :  1;
        uint8_t smrsten   :  1; // supply monitor reset enable
        uint8_t smien     :  1; // supply monitor interrupt enable
        uint8_t reserved2 :  2;
        uint16_t reserved3: 16;
    }  __attribute__((__packed__)) bits;
} supc_smmr_t;

#define SUPC_SMMR_SMTH_1_9V 0x0
#define SUPC_SMMR_SMTH_2_0V 0x1
#define SUPC_SMMR_SMTH_2_1V 0x2
#define SUPC_SMMR_SMTH_2_2V 0x3
#define SUPC_SMMR_SMTH_2_3V 0x4
#define SUPC_SMMR_SMTH_2_4V 0x5
#define SUPC_SMMR_SMTH_2_5V 0x6
#define SUPC_SMMR_SMTH_2_6V 0x7
#define SUPC_SMMR_SMTH_2_7V 0x8
#define SUPC_SMMR_SMTH_2_8V 0x9
#define SUPC_SMMR_SMTH_2_9V 0xA
#define SUPC_SMMR_SMTH_3_0V 0xB
#define SUPC_SMMR_SMTH_3_1V 0xC
#define SUPC_SMMR_SMTH_3_2V 0xD
#define SUPC_SMMR_SMTH_3_3V 0xE
#define SUPC_SMMR_SMTH_3_4V 0xF

#define SUPC_SMMR_SMSMPL_SMD      0x0
#define SUPC_SMMR_SMSMPL_CSM      0x1
#define SUPC_SMMR_SMSMPL_32SLCK   0x2
#define SUPC_SMMR_SMSMPL_256SLCK  0x3
#define SUPC_SMMR_SMSMPL_2048SLCK 0x4

/**
 * SUPC  Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 294
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t reserved0  : 12;
        uint8_t bodrsten    :  1; // brownout detector reset enable
        uint8_t boddis      :  1; // brownout detector disable
        uint8_t vddiordy    :  1; // VDDIO ready
        uint8_t reserved1   :  1;
        uint8_t reserved2   :  4;
        uint8_t oscbypass   :  1; // oscillator bypass
        uint8_t reserved3   :  3;
        uint8_t key         :  8; // key should be written to value 0xA5
    } __attribute__((__packed__)) bits;
} supc_mr_t;

#define SUPC_MR_KEY 0xA5

/**
 * SUPC Wake Up Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 295
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t fwupen      :  1; // force wake up enable
        uint8_t smen        :  1; // supply monitor wake up enable
        uint8_t rtten       :  1; // real time timer wake up enable
        uint8_t rtcen       :  1; // real time clock waek up enable
        uint8_t reserved0   :  4;
        uint8_t fwupdbc     :  3; // force wake up debouncer
        uint8_t reserved1   :  1;
        uint8_t wkupdbc     :  3; // wake up inputs debouncer
        uint8_t reserved2   :  1;
        uint16_t reserved3  : 16;
    } __attribute__((__packed__)) bits;
} supc_wumr_t;

#define SUPC_WUMR_FWUPDBC_1SCLK     0x0
#define SUPC_WUMR_FWUPDBC_3SCLK     0x1
#define SUPC_WUMR_FWUPDBC_32SCLK    0x2
#define SUPC_WUMR_FWUPDBC_512SCLK   0x3
#define SUPC_WUMR_FWUPDBC_4096SCLK  0x4
#define SUPC_WUMR_FWUPDBC_32768SCLK 0x5

#define SUPC_WUMR_WKUPDBC_1SCLK     0x0
#define SUPC_WUMR_WKUPDBC_3SCLK     0x1
#define SUPC_WUMR_WKUPDBC_32SCLK    0x2
#define SUPC_WUMR_WKUPDBC_512SCLK   0x3
#define SUPC_WUMR_WUKPDBC_4096SCLK  0x4
#define SUPC_WUMR_WKUPDBC_32768SCLK 0x5

/**
 * SUPC System Controller wake up inputs Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 297
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t wkupen0  : 1; // wake up input enable 0
        uint8_t wkupen1  : 1; // wake up input enable 1
        uint8_t wkupen2  : 1; // wake up input enable 2
        uint8_t wkupen3  : 1; // wake up input enable 3
        uint8_t wkupen4  : 1; // wake up input enable 4
        uint8_t wkupen5  : 1; // wake up input enable 5
        uint8_t wkupen6  : 1; // wake up input enable 6
        uint8_t wkupen7  : 1; // wake up input enable 7
        uint8_t wkupen8  : 1; // wake up input enable 8
        uint8_t wkupen9  : 1; // wake up input enable 9
        uint8_t wkupen10 : 1; // wake up input enable 10
        uint8_t wkupen11 : 1; // wake up input enable 11
        uint8_t wkupen12 : 1; // wake up input enable 12
        uint8_t wkupen13 : 1; // wake up input enable 13
        uint8_t wkupen14 : 1; // wake up input enable 14
        uint8_t wkupen15 : 1; // wake up input enable 15
        uint8_t wkupt0   : 1; // wake up input transition 0
        uint8_t wkupt1   : 1; // wake up input transition 1
        uint8_t wkupt2   : 1; // wake up input transition 2
        uint8_t wkupt3   : 1; // wake up input transition 3
        uint8_t wkupt4   : 1; // wake up input transition 4
        uint8_t wkupt5   : 1; // wake up input transition 5
        uint8_t wkupt6   : 1; // wake up input transition 6
        uint8_t wkupt7   : 1; // wake up input transition 7
        uint8_t wkupt8   : 1; // wake up input transition 8
        uint8_t wkupt9   : 1; // wake up input transition 9
        uint8_t wkupt10  : 1; // wake up input transition 10
        uint8_t wkupt11  : 1; // wake up input transition 11
        uint8_t wkupt12  : 1; // wake up input transition 12
        uint8_t wkupt13  : 1; // wake up input transition 13
        uint8_t wkupt14  : 1; // wake up input transition 14
        uint8_t wkupt15  : 1; // wake up input transition 15
    } __attribute__((__packed__)) bits;
} supc_wuir_t;

/**
 * SUPC Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 298
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t fwups      :  1; // fwup wake up status
        uint8_t wkups      :  1; // wkup wake up status
        uint8_t smws       :  1; // supply monitor detection wake up status
        uint8_t bodrsts    :  1; // brownout detector reset status
        uint8_t smrsts     :  1; // supply monitor reset status
        uint8_t sms        :  1; // supply monitor status
        uint8_t smos       :  1; // supply monitor output status
        uint8_t oscsel     :  1; // 32-khz oscillator selection status
        uint8_t reserved0  :  4;
        uint8_t fwupis     :  1; // fwup input status
        uint8_t reserved1  :  3;
        uint8_t wkupis0    :  1; // wkup input status 0
        uint8_t wkupis1    :  1; // wkup input status 1
        uint8_t wkupis2    :  1; // wkup input status 2
        uint8_t wkupis3    :  1; // wkup input status 3
        uint8_t wkupis4    :  1; // wkup input status 4
        uint8_t wkupis5    :  1; // wkup input status 5
        uint8_t wkupis6    :  1; // wkup input status 6
        uint8_t wkupis7    :  1; // wkup input status 7
        uint8_t wkupis8    :  1; // wkup input status 8
        uint8_t wkupis9    :  1; // wkup input status 9
        uint8_t wkupis10   :  1; // wkup input status 10
        uint8_t wkupis11   :  1; // wkup input status 11
        uint8_t wkupis12   :  1; // wkup input status 12
        uint8_t wkupis13   :  1; // wkup input status 13
        uint8_t wkupis14   :  1; // wkup input status 14
        uint8_t wkupis15   :  1; // wkup input status 15
    } __attribute__((__packed__)) bits;
} supc_sr_t;

/**
 * SUPC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 290
 */
typedef struct supc
{
    volatile supc_cr_t cr;     // Control Register
    volatile supc_smmr_t smmr; // Supply Monitor Mode Register
    volatile supc_mr_t mr;     // Mode Register
    volatile supc_wumr_t wumr; // Wake Up Mode Register
    volatile supc_wuir_t wuir; // Wake Up Inputs Register
    volatile supc_sr_t sr;     // Status Register
} supc_t;


#endif // SUPCHARDWARE_H
