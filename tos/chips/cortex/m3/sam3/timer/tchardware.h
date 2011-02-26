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
 * Timer Counter register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef TCHARDWARE_H
#define TCHARDWARE_H

/**
 *  TC Block Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 828
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t sync      : 1; // synchro command
        uint32_t reserved0 : 7;
        uint32_t reserved1 : 8;
        uint32_t reserved2 : 8;
    } __attribute__((packed)) bits;
} tc_bcr_t;

/**
 *  TC Block Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 829
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t tc0xc0s    : 2; // external clock signal 0 selection
        uint32_t tc1xc1s    : 2; // external clock signal 1 selection
        uint32_t tc2xc2s    : 2; // external clock signal 2 selection
        uint32_t reserved0  : 2;
        uint32_t qden       : 1; // quadrature decoder enabled
        uint32_t posen      : 1; // position enabled
        uint32_t speeden    : 1; // speed enabled
        uint32_t qdtrans    : 1; // quadrature decoding transparent
        uint32_t edgpha     : 1; // edge on pha count mode
        uint32_t inva       : 1; // invert pha
        uint32_t invb       : 1; // invert phb
        uint32_t invidx     : 1; // swap pha and phb
        uint32_t swap       : 1; // inverted index
        uint32_t idxphb     : 1; // index pin is phb pin
        uint32_t reserved1  : 1;
        uint32_t filter     : 1; // filter
        uint32_t maxfilt    : 6; // maximum filter
        uint32_t reserved2  : 6;
    } __attribute__((packed)) bits;
} tc_bmr_t;

/**
 *  TC Channel Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 831 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t clken      :  1; // counter clock enable command
        uint32_t clkdis     :  1; // counter clock disable command
        uint32_t swtrg      :  1; // software trigger command
        uint32_t reserved0  :  5;
        uint32_t reserved1  :  8;
        uint32_t reserved2  : 16;
    } __attribute__((packed)) bits;
} tc_ccr_t;

/**
 *  TC QDEC Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 832 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t idx        :  1; // index
        uint32_t dirchg     :  1; // direction change
        uint32_t qerr       :  1; // quadrature error
        uint32_t reserved0  :  5;
        uint32_t reserved1  :  8;
        uint32_t reserved2  : 16;
    } __attribute__((packed)) bits;
} tc_qier_t;

/**
 *  TC QDEC Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 833
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t idx        :  1; // index
        uint32_t dirchg     :  1; // direction change
        uint32_t qerr       :  1; // quadrature error
        uint32_t reserved0  :  5;
        uint32_t reserved1  :  8;
        uint32_t reserved2  : 16;
    } __attribute__((packed)) bits;
} tc_qidr_t;

/**
 *  TC QDEC Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 834
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t idx        :  1; // index
        uint32_t dirchg     :  1; // direction change
        uint32_t qerr       :  1; // quadrature error
        uint32_t reserved0  :  5;
        uint32_t reserved1  :  8;
        uint32_t reserved2  : 16;
    } __attribute__((packed)) bits;
} tc_qimr_t;

/**
 *  TC QDEC Interrupt Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 835 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t idx        :  1; // index
        uint32_t dirchg     :  1; // direction change
        uint32_t qerr       :  1; // quadrature error
        uint32_t reserved0  :  5;
        uint32_t dir        :  1; // direction
        uint32_t reserved1  :  7;
        uint32_t reserved2 : 16;
    } __attribute__((packed)) bits;
} tc_qisr_t;

/**
 *  TC Channel Mode Register Capture Mode, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 836
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t tcclks    : 3; // clock selection
        uint32_t clki      : 1; // clock invert
        uint32_t burst     : 2; // burst signal selection
        uint32_t ldbstop   : 1; // counter clock stopped with rb loading
        uint32_t ldbdis    : 1; // counter clock disable with rb loading
        uint32_t etrgedg   : 2; // external trigger edge selection
        uint32_t abetrg    : 1; // tioa or tiob external trigger selection
        uint32_t reserved0 : 3;
        uint32_t cpctrg    : 1; // rc compare trigger enable
        uint32_t wave      : 1; // wave
        uint32_t ldra      : 2; // ra loading selection
        uint32_t ldrb      : 2; // rb loading selection
        uint32_t reserved1 : 4;
        uint32_t reserved2 : 8;
    } __attribute__((packed)) bits;
} tc_cmr_capture_t;

#define TC_CMR_ETRGEDG_NONE     0 
#define TC_CMR_ETRGEDG_RISING   1
#define TC_CMR_ETRGEDG_FALLING  2
#define TC_CMR_ETRGEDG_EACH     3

#define TC_CMR_CAPTURE          0
#define TC_CMR_WAVE             1

#define TC_CMR_CLK_TC1          0
#define TC_CMR_CLK_TC2          1
#define TC_CMR_CLK_TC3          2
#define TC_CMR_CLK_TC4          3
#define TC_CMR_CLK_SLOW         4
#define TC_CMR_CLK_XC0          5
#define TC_CMR_CLK_XC1          6
#define TC_CMR_CLK_XC2          7

#define TC_CMR_ABETRG_TIOA      0
#define TC_CMR_ABETRG_TIOB      1

/**
 *  TC Channel Mode Register Waveform Mode, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 838
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t tcclks    : 3; // clock selection
        uint32_t clki      : 1; // clock invert
        uint32_t burst     : 2; // burst signal selection
        uint32_t cpcstop   : 1; // counter clock stopped with rc compare
        uint32_t cpcdis    : 1; // counter clock disable with rc compare
        uint32_t eevtedg   : 2; // external event edge selection
        uint32_t eevt      : 2; // external event selection
        uint32_t enetrg    : 1; // external event trigger enable
        uint32_t wavsel    : 2; // waveform selection
        uint32_t wave      : 1; // wave
        uint32_t acpa      : 2; // ra compare effect on tioa
        uint32_t acpc      : 2; // rc compare effect on tioa
        uint32_t aeevt     : 2; // external event effect on tioa
        uint32_t aswtrg    : 2; // software trigger effect on tioa
        uint32_t bcpb      : 2; // rb compare effect on tiob
        uint32_t bcpc      : 2; // rc compare effect on tiob
        uint32_t beevt     : 2; // external event effect on tiob
        uint32_t bswtrg    : 2; // software trigger effect on tiob
    } __attribute__((packed)) bits;
} tc_cmr_wave_t;

/**
 *  TC Counter Value Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 842 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cv       : 16; // counter value
        uint32_t reserved : 16;
    } __attribute__((packed)) bits;
} tc_cv_t;

/**
 *  TC Register A, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 842 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ra        : 16; // register a
        uint32_t reserved  : 16;
    } __attribute__((packed)) bits;
} tc_ra_t;

/**
 *  TC Register B, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 843 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t rb        : 16; // register b
        uint32_t reserved  : 16;
    } __attribute__((packed)) bits;
} tc_rb_t;

/**
 *  TC Register C, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 843 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t rc        : 16; // register c
        uint32_t reserved  : 16;
    } __attribute__((packed)) bits;
} tc_rc_t;

/**
 *  TC Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 844
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t covfs      : 1; // counter overflow status
        uint32_t lovrs      : 1; // load overrun status
        uint32_t cpas       : 1; // ra compare status
        uint32_t cpbs       : 1; // rb compare status
        uint32_t cpcs       : 1; // rc compare status
        uint32_t ldras      : 1; // ra loading status
        uint32_t ldrbs      : 1; // rb loading status
        uint32_t etrgs      : 1; // external trigger status
        uint32_t reserved0  : 8;
        uint32_t clksta     : 1; // clock enable status
        uint32_t mtioa      : 1; // tioa mirror
        uint32_t mtiob      : 1; // tiob mirror
        uint32_t reserved1  : 5;
        uint32_t reserved2  : 8;
    } __attribute__((packed)) bits;
} tc_sr_t;

/**
 *  TC Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 846 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t covfs      : 1; // counter overflow 
        uint32_t lovrs      : 1; // load overrun 
        uint32_t cpas       : 1; // ra compare 
        uint32_t cpbs       : 1; // rb compare 
        uint32_t cpcs       : 1; // rc compare 
        uint32_t ldras      : 1; // ra loading 
        uint32_t ldrbs      : 1; // rb loading 
        uint32_t etrgs      : 1; // external trigger 
        uint32_t reserved0  : 8;
        uint32_t reserved1  :16;
    } __attribute__((packed)) bits;
} tc_ier_t;

/**
 *  TC Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 847 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t covfs      : 1; // counter overflow 
        uint32_t lovrs      : 1; // load overrun 
        uint32_t cpas       : 1; // ra compare 
        uint32_t cpbs       : 1; // rb compare 
        uint32_t cpcs       : 1; // rc compare 
        uint32_t ldras      : 1; // ra loading 
        uint32_t ldrbs      : 1; // rb loading 
        uint32_t etrgs      : 1; // external trigger 
        uint32_t reserved0  : 8;
        uint32_t reserved1  :16;
    } __attribute__((packed)) bits;
} tc_idr_t;

/**
 *  TC Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 848 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t covfs      : 1; // counter overflow 
        uint32_t lovrs      : 1; // load overrun 
        uint32_t cpas       : 1; // ra compare 
        uint32_t cpbs       : 1; // rb compare 
        uint32_t cpcs       : 1; // rc compare 
        uint32_t ldras      : 1; // ra loading 
        uint32_t ldrbs      : 1; // rb loading 
        uint32_t etrgs      : 1; // external trigger 
        uint32_t reserved0  : 8;
        uint32_t reserved1  :16;
    } __attribute__((packed)) bits;
} tc_imr_t;

/**
 * Channel definition capture mode
 */
typedef struct
{
    volatile tc_ccr_t ccr;
    volatile tc_cmr_capture_t cmr;
    uint32_t reserved[2];
    volatile tc_cv_t cv;
    volatile tc_ra_t ra;
    volatile tc_rb_t rb;
    volatile tc_rc_t rc;
    volatile tc_sr_t sr;
    volatile tc_ier_t ier;
    volatile tc_idr_t idr;
    volatile tc_imr_t imr;
} tc_channel_capture_t;

/**
 * Channel definition wave mode
 */
typedef struct
{
    volatile tc_ccr_t ccr;
    volatile tc_cmr_wave_t cmr;
    uint32_t reserved[2];
    volatile tc_cv_t cv;
    volatile tc_ra_t ra;
    volatile tc_rb_t rb;
    volatile tc_rc_t rc;
    volatile tc_sr_t sr;
    volatile tc_ier_t ier;
    volatile tc_idr_t idr;
    volatile tc_imr_t imr;
} tc_channel_wave_t;

#endif //TCHARDWARE_H

