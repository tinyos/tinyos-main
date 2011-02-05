/*
 * Copyright (c) 2011 University of Utah.
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Sam3s PWM register definitions
 *
 * @author Thomas Schmid
 */

#ifndef SAM3SPWMHARDWARE_H
#define SAM3SPWMHARDWARE_H

#define PWM_COMPARE_DAC 0
#define PWM_COMPARE_ADC 1
#define PWM_EVENT_DAC 0
#define PWM_EVENT_ADC 1

/**
 * PWM Clock Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t diva      : 8; // clock divider A
        uint32_t prea      : 4; // clock source selection
        uint32_t reserved0 : 4;
        uint32_t divb      : 8; // clock divider B
        uint32_t preb      : 4; // clock source selection
        uint32_t reserved1 : 4;
    } __attribute__((__packed__)) bits;
} pwm_clk_t;

/**
 * PWM Enable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved   : 28;
    } __attribute__((__packed__)) bits;
} pwm_ena_t;

/**
 * PWM Disable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved   : 28;
    } __attribute__((__packed__)) bits;
} pwm_dis_t;

/**
 * PWM Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved   : 28;
    } __attribute__((__packed__)) bits;
} pwm_sr_t;

/**
 * PWM Interrupt Enable Register 1
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved0  : 12;
        uint32_t fchid0     :  1; // channel 0
        uint32_t fchid1     :  1; // channel 1
        uint32_t fchid2     :  1; // channel 2
        uint32_t fchid3     :  1; // channel 3
        uint32_t reserved1  : 12;
    } __attribute__((__packed__)) bits;
} pwm_ier1_t;

/**
 * PWM Interrupt Disable Register 1
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved0  : 12;
        uint32_t fchid0     :  1; // channel 0
        uint32_t fchid1     :  1; // channel 1
        uint32_t fchid2     :  1; // channel 2
        uint32_t fchid3     :  1; // channel 3
        uint32_t reserved1  : 12;
    } __attribute__((__packed__)) bits;
} pwm_idr1_t;

/**
 * PWM Interrupt Mask Register 1
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved0  : 12;
        uint32_t fchid0     :  1; // channel 0
        uint32_t fchid1     :  1; // channel 1
        uint32_t fchid2     :  1; // channel 2
        uint32_t fchid3     :  1; // channel 3
        uint32_t reserved1  : 12;
    } __attribute__((__packed__)) bits;
} pwm_imr1_t;

/**
 * PWM Interrupt Status Register 1
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t chid0      :  1; // channel 0
        uint32_t chid1      :  1; // channel 1
        uint32_t chid2      :  1; // channel 2
        uint32_t chid3      :  1; // channel 3
        uint32_t reserved0  : 12;
        uint32_t fchid0     :  1; // channel 0
        uint32_t fchid1     :  1; // channel 1
        uint32_t fchid2     :  1; // channel 2
        uint32_t fchid3     :  1; // channel 3
        uint32_t reserved1  : 12;
    } __attribute__((__packed__)) bits;
} pwm_isr1_t;

/**
 * PWM Sync channels Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t sync0     :  1;
        uint32_t sync1     :  1;
        uint32_t sync2     :  1;
        uint32_t sync3     :  1;
        uint32_t reserved0 : 12;
        uint32_t updm      :  2; // sync channel update mode
        uint32_t reserved1 :  2;
        uint32_t ptrm      :  1; // PDC Transfer Request Mode
        uint32_t ptrcs     :  3; // PDC Transfer Request Comparison Selection
        uint32_t reserved2 :  8;
    } __attribute__((__packed__)) bits;
} pwm_scm_t;

/**
 * PWM Sync Channels Update Control Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t updulock    :  1; // Synchronous Channels Update Unlock
        uint32_t reserved    : 31;
    } __attribute__((__packed__)) bits;
} pwm_scuc_t;

/**
 * PWM Sync Channels Update Period Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t upr      :  4; // update period
        uint32_t uprcnt   :  4; // update period counter
        uint32_t reserved : 24;
    } __attribute__((__packed__)) bits;
} pwm_scup_t;

/**
 * PWM Sync Channels Update Period Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t uprupd      :  4; // update period update
        uint32_t reserved    : 28;
    } __attribute__((__packed__)) bits;
} pwm_scupupd_t;

/**
 * PWM Interrupt Enable Register 2
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wrdy      : 1; // write ready for synchronous channel update interrupt enable
        uint32_t endtx     : 1; // pdc end of tx buffer
        uint32_t txbufe    : 1; // pdc tx buffer empty
        uint32_t unre      : 1; // sync channels update underrun error
        uint32_t reserved0 : 4;
        uint32_t cmpm0     : 1; // comparison x match interrupt
        uint32_t cmpm1     : 1; // comparison x match interrupt
        uint32_t cmpm2     : 1; // comparison x match interrupt
        uint32_t cmpm3     : 1; // comparison x match interrupt
        uint32_t cmpm4     : 1; // comparison x match interrupt
        uint32_t cmpm5     : 1; // comparison x match interrupt
        uint32_t cmpm6     : 1; // comparison x match interrupt
        uint32_t cmpm7     : 1; // comparison x match interrupt
        uint32_t cmpu0     : 1; // comparison x update interrupt
        uint32_t cmpu1     : 1; // comparison x update interrupt
        uint32_t cmpu2     : 1; // comparison x update interrupt
        uint32_t cmpu3     : 1; // comparison x update interrupt
        uint32_t cmpu4     : 1; // comparison x update interrupt
        uint32_t cmpu5     : 1; // comparison x update interrupt
        uint32_t cmpu6     : 1; // comparison x update interrupt
        uint32_t cmpu7     : 1; // comparison x update interrupt
        uint32_t reserved1 : 8;
    } __attribute__((__packed__)) bits;
} pwm_ier2_t;

/**
 * PWM Interrupt Disable Register 2
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wrdy      : 1; // write ready for synchronous channel update interrupt enable
        uint32_t endtx     : 1; // pdc end of tx buffer
        uint32_t txbufe    : 1; // pdc tx buffer empty
        uint32_t unre      : 1; // sync channels update underrun error
        uint32_t reserved0 : 4;
        uint32_t cmpm0     : 1; // comparison x match interrupt
        uint32_t cmpm1     : 1; // comparison x match interrupt
        uint32_t cmpm2     : 1; // comparison x match interrupt
        uint32_t cmpm3     : 1; // comparison x match interrupt
        uint32_t cmpm4     : 1; // comparison x match interrupt
        uint32_t cmpm5     : 1; // comparison x match interrupt
        uint32_t cmpm6     : 1; // comparison x match interrupt
        uint32_t cmpm7     : 1; // comparison x match interrupt
        uint32_t cmpu0     : 1; // comparison x update interrupt
        uint32_t cmpu1     : 1; // comparison x update interrupt
        uint32_t cmpu2     : 1; // comparison x update interrupt
        uint32_t cmpu3     : 1; // comparison x update interrupt
        uint32_t cmpu4     : 1; // comparison x update interrupt
        uint32_t cmpu5     : 1; // comparison x update interrupt
        uint32_t cmpu6     : 1; // comparison x update interrupt
        uint32_t cmpu7     : 1; // comparison x update interrupt
        uint32_t reserved1 : 8;
    } __attribute__((__packed__)) bits;
} pwm_idr2_t;

/**
 * PWM Interrupt Mask Register 2
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wrdy      : 1; // write ready for synchronous channel update interrupt enable
        uint32_t endtx     : 1; // pdc end of tx buffer
        uint32_t txbufe    : 1; // pdc tx buffer empty
        uint32_t unre      : 1; // sync channels update underrun error
        uint32_t reserved0 : 4;
        uint32_t cmpm0     : 1; // comparison x match interrupt
        uint32_t cmpm1     : 1; // comparison x match interrupt
        uint32_t cmpm2     : 1; // comparison x match interrupt
        uint32_t cmpm3     : 1; // comparison x match interrupt
        uint32_t cmpm4     : 1; // comparison x match interrupt
        uint32_t cmpm5     : 1; // comparison x match interrupt
        uint32_t cmpm6     : 1; // comparison x match interrupt
        uint32_t cmpm7     : 1; // comparison x match interrupt
        uint32_t cmpu0     : 1; // comparison x update interrupt
        uint32_t cmpu1     : 1; // comparison x update interrupt
        uint32_t cmpu2     : 1; // comparison x update interrupt
        uint32_t cmpu3     : 1; // comparison x update interrupt
        uint32_t cmpu4     : 1; // comparison x update interrupt
        uint32_t cmpu5     : 1; // comparison x update interrupt
        uint32_t cmpu6     : 1; // comparison x update interrupt
        uint32_t cmpu7     : 1; // comparison x update interrupt
        uint32_t reserved1 : 8;
    } __attribute__((__packed__)) bits;
} pwm_imr2_t;

/**
 * PWM Interrupt Status Register 2
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wrdy      : 1; // write ready for synchronous channel update interrupt enable
        uint32_t endtx     : 1; // pdc end of tx buffer
        uint32_t txbufe    : 1; // pdc tx buffer empty
        uint32_t unre      : 1; // sync channels update underrun error
        uint32_t reserved0 : 4;
        uint32_t cmpm0     : 1; // comparison x match interrupt
        uint32_t cmpm1     : 1; // comparison x match interrupt
        uint32_t cmpm2     : 1; // comparison x match interrupt
        uint32_t cmpm3     : 1; // comparison x match interrupt
        uint32_t cmpm4     : 1; // comparison x match interrupt
        uint32_t cmpm5     : 1; // comparison x match interrupt
        uint32_t cmpm6     : 1; // comparison x match interrupt
        uint32_t cmpm7     : 1; // comparison x match interrupt
        uint32_t cmpu0     : 1; // comparison x update interrupt
        uint32_t cmpu1     : 1; // comparison x update interrupt
        uint32_t cmpu2     : 1; // comparison x update interrupt
        uint32_t cmpu3     : 1; // comparison x update interrupt
        uint32_t cmpu4     : 1; // comparison x update interrupt
        uint32_t cmpu5     : 1; // comparison x update interrupt
        uint32_t cmpu6     : 1; // comparison x update interrupt
        uint32_t cmpu7     : 1; // comparison x update interrupt
        uint32_t reserved1 : 8;
    } __attribute__((__packed__)) bits;
} pwm_isr2_t;

/**
 * PWM Output Override Value Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t oovh0     :  1; // Output Override value for pwmh output of the channel x
        uint32_t oovh1     :  1; // Output Override value for pwmh output of the channel x
        uint32_t oovh2     :  1; // Output Override value for pwmh output of the channel x
        uint32_t oovh3     :  1; // Output Override value for pwmh output of the channel x
        uint32_t reserved0 : 12;
        uint32_t oovl0     :  1; // output override value for pwml output of the channel x
        uint32_t oovl1     :  1; // output override value for pwml output of the channel x
        uint32_t oovl2     :  1; // output override value for pwml output of the channel x
        uint32_t oovl3     :  1; // output override value for pwml output of the channel x
        uint32_t reserved1 : 12;
    } __attribute__((__packed__)) bits;
} pwm_oov_t;

/**
 * PWM Output Selection Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t osh0      :  1; // Output Selection for PWMH output of the channel x 
        uint32_t osh1      :  1; // Output Selection for PWMH output of the channel x 
        uint32_t osh2      :  1; // Output Selection for PWMH output of the channel x 
        uint32_t osh3      :  1; // Output Selection for PWMH output of the channel x 
        uint32_t reserved0 : 12;
        uint32_t osl0      :  1; // output selection for PWML output of the channel x 
        uint32_t osl1      :  1; // output selection for PWML output of the channel x 
        uint32_t osl2      :  1; // output selection for PWML output of the channel x 
        uint32_t osl3      :  1; // output selection for PWML output of the channel x 
        uint32_t reserved1 : 12;

    } __attribute__((__packed__)) bits;
} pwm_os_t;

/**
 * PWM Output Selection Set Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ossh0     :  1; // Output Selection Set for PWMH output of the channel x
        uint32_t ossh1     :  1; // Output Selection Set for PWMH output of the channel x
        uint32_t ossh2     :  1; // Output Selection Set for PWMH output of the channel x
        uint32_t ossh3     :  1; // Output Selection Set for PWMH output of the channel x
        uint32_t reserved0 : 12;
        uint32_t ossl0     :  1; // Output Selection Set for PWML output of the channel x
        uint32_t ossl1     :  1; // Output Selection Set for PWML output of the channel x
        uint32_t ossl2     :  1; // Output Selection Set for PWML output of the channel x
        uint32_t ossl3     :  1; // Output Selection Set for PWML output of the channel x
        uint32_t reserved1 : 12;
    } __attribute__((__packed__)) bits;
} pwm_oss_t;

/**
 * PWM Output Selection Clear Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t osch0     :  1;
        uint32_t osch1     :  1;
        uint32_t osch2     :  1;
        uint32_t osch3     :  1;
        uint32_t reserved0 : 12;
        uint32_t oscl0     :  1;
        uint32_t oscl1     :  1;
        uint32_t oscl2     :  1;
        uint32_t oscl3     :  1;
        uint32_t reserved1 : 12;
    } __attribute__((__packed__)) bits;
} pwm_osc_t;

/**
 * PWM Output Selection Set Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ossuph0    :  1;
        uint32_t ossuph1    :  1;
        uint32_t ossuph2    :  1;
        uint32_t ossuph3    :  1;
        uint32_t reserved0  : 12;
        uint32_t ossupl0    :  1;
        uint32_t ossupl1    :  1;
        uint32_t ossupl2    :  1;
        uint32_t ossupl3    :  1;
        uint32_t reserved1  : 12;
    } __attribute__((__packed__)) bits;
} pwm_ossupd_t;

/**
 * PWM Output Selection Clear Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t oscuph0     :  1;
        uint32_t oscuph1     :  1;
        uint32_t oscuph2     :  1;
        uint32_t oscuph3     :  1;
        uint32_t reserved0   : 12;
        uint32_t oscupl0     :  1;
        uint32_t oscupl1     :  1;
        uint32_t oscupl2     :  1;
        uint32_t oscupl3     :  1;
        uint32_t reserved1   : 12;
    } __attribute__((__packed__)) bits;
} pwm_oscupd_t;

/**
 * PWM Fault Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t fpol     : 8;
        uint32_t fmod     : 8;
        uint32_t ffil     : 8;
        uint32_t reserved : 8;
    } __attribute__((__packed__)) bits;
} pwm_fmr_t;

/**
 * PWM Fault Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t fiv      :  8;
        uint32_t fs       :  8;
        uint32_t reserved : 16;
    } __attribute__((__packed__)) bits;
} pwm_fsr_t;

/**
 * PWM Fault Clear Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t fclr     :  8;
        uint32_t reserved : 24;
    } __attribute__((__packed__)) bits;
} pwm_fcr_t;

/**
 * PWM Fault Protection Value Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t fpvh0     :  1;
        uint32_t fpvh1     :  1;
        uint32_t fpvh2     :  1;
        uint32_t fpvh3     :  1;
        uint32_t reserved0 : 12;
        uint32_t fpvl0     :  1;
        uint32_t fpvl1     :  1;
        uint32_t fpvl2     :  1;
        uint32_t fpvl3     :  1;
    } __attribute__((__packed__)) bits;
} pwm_fpv_t;

/**
 * PWM Fault Protection Enable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t fpe0 : 8;
        uint32_t fpe1 : 8;
        uint32_t fpe2 : 8;
        uint32_t fpe3 : 8;
    } __attribute__((__packed__)) bits;
} pwm_fpe_t;

/**
 * PWM Event Line x Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t csel0       :  1;
        uint32_t csel1       :  1;
        uint32_t csel2       :  1;
        uint32_t csel3       :  1;
        uint32_t csel4       :  1;
        uint32_t csel5       :  1;
        uint32_t csel6       :  1;
        uint32_t csel7       :  1;
        uint32_t reserved    : 24;
    } __attribute__((__packed__)) bits;
} pwm_elmr_t;

/**
 * PWM Stepper Motor Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t gcen0     :  1;
        uint32_t gcen1     :  1;
        uint32_t reserved0 : 14;
        uint32_t down0     :  1;
        uint32_t down1     :  1;
        uint32_t reserved1 : 14;
    } __attribute__((__packed__)) bits;
} pwm_smmr_t;

/**
 * PWM Write Protect Control Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wpcmd     :  2;
        uint32_t wprg0     :  1;
        uint32_t wprg1     :  1;
        uint32_t wprg2     :  1;
        uint32_t wprg3     :  1;
        uint32_t wprg4     :  1;
        uint32_t wprg5     :  1;
        uint32_t wpkey     : 24;
    } __attribute__((__packed__)) bits;
} pwm_wpcr_t;

#define PWM_WPCR_KEY 0x50574D

/**
 * PWM Write Protect Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wpsws0     :  1;
        uint32_t wpsws1     :  1;
        uint32_t wpsws2     :  1;
        uint32_t wpsws3     :  1;
        uint32_t wpsws4     :  1;
        uint32_t wpsws5     :  1;
        uint32_t reserved0  :  1;
        uint32_t wpvs       :  1;
        uint32_t wphws0     :  1;
        uint32_t wphws1     :  1;
        uint32_t wphws2     :  1;
        uint32_t wphws3     :  1;
        uint32_t wphws4     :  1;
        uint32_t wphws5     :  1;
        uint32_t reserved1  :  2;
        uint32_t wpvsrc     : 16;
    } __attribute__((__packed__)) bits;
} pwm_wpsr_t;

/**
 * PWM Comparison x Value Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cv        : 24;
        uint32_t cvm       :  1;
        uint32_t reserved  :  7;
    } __attribute__((__packed__)) bits;
} pwm_cmpv_t;

/**
 * PWM Comparison x Value Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cvupd     : 24;
        uint32_t cvmupd    :  1;
        uint32_t reserved  :  7;
    } __attribute__((__packed__)) bits;
} pwm_cmpvupd_t;

/**
 * PWM Comparison x Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cen        : 1;
        uint32_t reserved0  : 3;
        uint32_t ctr        : 4;
        uint32_t cpr        : 4;
        uint32_t cprcnt     : 4;
        uint32_t cupr       : 4;
        uint32_t cuprcnt    : 4;
        uint32_t reserved1  : 8;
    } __attribute__((__packed__)) bits;
} pwm_cmpm_t;

/**
 * PWM Comparison x Mode Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cenupd     :  1;
        uint32_t reserved0  :  3;
        uint32_t ctrupd     :  4;
        uint32_t cprupd     :  4;
        uint32_t reserved1  :  4;
        uint32_t cuprupd    :  4;
        uint32_t reserved2  : 12;
    } __attribute__((__packed__)) bits;
} pwm_cmpmupd_t;

/**
 * PWM Channel Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cpre       :  4;
        uint32_t reserved0  :  4;
        uint32_t calg       :  1;
        uint32_t cpol       :  1;
        uint32_t ces        :  1;
        uint32_t reserved1  :  5;
        uint32_t dte        :  1;
        uint32_t dthi       :  1;
        uint32_t dtli       :  1;
        uint32_t reserved2  : 13;
    } __attribute__((__packed__)) bits;
} pwm_cmr_t;

#define PWM_CMR_CPRE_CLKA 11
#define PWM_CMR_CPRE_CLKB 12

/**
 * PWM Channel Duty Cycle Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cdty       : 24;
        uint32_t reserved   :  8;
    } __attribute__((__packed__)) bits;
} pwm_cdty_t;

/**
 * PWM Channe Duty Cycle Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cdtyupd   : 24;
        uint32_t reserved  : 8;
    } __attribute__((__packed__)) bits;
} pwm_cdtyupd_t;

/**
 * PWM Channel Period Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cprd     : 24;
        uint32_t reserved :  8;
    } __attribute__((__packed__)) bits;
} pwm_cprd_t;

/**
 * PWM Channel Period Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cprdupd  : 24;
        uint32_t reserved :  8;
    } __attribute__((__packed__)) bits;
} pwm_cprdupd_t;

/**
 * PWM Channel Counter Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cnt      : 24;
        uint32_t reserved :  8;
    } __attribute__((__packed__)) bits;
} pwm_ccnt_t;

/**
 * PWM Channel Dead Time Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t dth : 16;
        uint32_t dtl : 16;
    } __attribute__((__packed__)) bits;
} pwm_dt_t;

/**
 * PWM Channel Dead Time Update Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t dthupd : 16;
        uint32_t dtlupd : 16;
    } __attribute__((__packed__)) bits;
} pwm_dtupd_t;

typedef struct pwm_comparison
{
    pwm_cmpv_t    cmpv;
    pwm_cmpvupd_t cmpvupd;
    pwm_cmpm_t    cmpm;
    pwm_cmpmupd_t cmpmupd;
} pwm_comparison_t;

typedef struct pwm_channel
{
    pwm_cmr_t     cmr;
    pwm_cdty_t    cdty;
    pwm_cdtyupd_t cdtyupd;
    pwm_cprd_t    cprd;
    pwm_cprdupd_t cprdupd;
    pwm_ccnt_t    ccnt;
    pwm_dt_t      dt;
    pwm_dtupd_t   dtupd;
} pwm_channel_t;

/**
 * PWM Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3S
 * Series, Preliminary, p. 875
 */
typedef struct pwm
{
    volatile pwm_clk_t        clk;
    volatile pwm_ena_t        ena;
    volatile pwm_dis_t        dis;
    volatile pwm_sr_t         sr;
    volatile pwm_ier1_t       ier1;
    volatile pwm_idr1_t       idr1;
    volatile pwm_imr1_t       imr1;
    volatile pwm_isr1_t       isr1;
    volatile pwm_scm_t        scm;
    uint32_t reserved0;
    volatile pwm_scuc_t       scuc;
    volatile pwm_scup_t       scup;
    volatile pwm_scupupd_t    scupupd;
    volatile pwm_ier2_t       ier2;
    volatile pwm_idr2_t       idr2;
    volatile pwm_imr2_t       imr2;
    volatile pwm_isr2_t       isr2;
    volatile pwm_oov_t        oov;
    volatile pwm_os_t         os;
    volatile pwm_oss_t        oss;
    volatile pwm_osc_t        osc;
    volatile pwm_ossupd_t     ossupd;
    volatile pwm_oscupd_t     oscupd;
    volatile pwm_fmr_t        fmr;
    volatile pwm_fsr_t        fsr;
    volatile pwm_fcr_t        fcr;
    volatile pwm_fpv_t        fpv;
    volatile pwm_fpe_t        fpe;
    uint32_t reserved1[3];
    volatile pwm_elmr_t       elm0r;
    volatile pwm_elmr_t       elm1r;
    uint32_t reserved2[11];
    volatile pwm_smmr_t       smmr;
    uint32_t reserved3[12];
    volatile pwm_wpcr_t       wpcr;
    volatile pwm_wpsr_t       wpsr;
    uint32_t reserved4[17];
    volatile pwm_comparison_t comparison[8];
    uint32_t reserved5[20];
    volatile pwm_channel_t    channel[4];
} pwm_t;

/**
 * Memory mapping for the PWM
 */
#define PWM_BASE_ADDRESS 0x40020000
volatile pwm_t* PWM = (volatile pwm_t *) PWM_BASE_ADDRESS;

#endif //SAM3SPWMHARDWARE_H


