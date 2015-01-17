/*
 * Copyright (c) 2011 University of Utah. 
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
 *
 *
 * @author Thomas Schmid
 */

#ifndef __CC2520XDRIVERLAYER_H__
#define __CC2520XDRIVERLAYER_H__

typedef nx_struct cc2520_header_t
{
	nxle_uint8_t length;
} cc2520_header_t;


typedef struct cc2520_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
	  uint8_t ack;
		uint8_t rssi;
	}__attribute__((packed));
} __attribute__((packed)) cc2520_metadata_t;

enum cc2520_reg_access_enums {
    CC2520_FREG_MASK      = 0x3F,    // highest address in FREG
    CC2520_SREG_MASK      = 0x7F,    // highest address in SREG
    CC2520_CMD_TXRAM_WRITE	  = 0x80, // FIXME: not sure... might need to change
};

typedef union cc2520_status {
	uint16_t value;
	struct {
	  unsigned  rx_active    :1;
	  unsigned  tx_active    :1;
	  unsigned  dpu_l_active :1;
	  unsigned  dpu_h_active :1;

	  unsigned  exception_b  :1;
	  unsigned  exception_a  :1;
	  unsigned  rssi_valid   :1;
	  unsigned  xosc_stable  :1;
	};
} cc2520_status_t;

typedef union cc2520_frmctrl0 {
    uint8_t value;
    struct {
        unsigned tx_mode          : 2;
        unsigned rx_mode          : 2;
        unsigned energy_scan      : 1;
        unsigned autoack          : 1;
        unsigned autocrc          : 1;
        unsigned append_data_mode : 1;
    } f;
} cc2520_frmctrl0_t;

static cc2520_frmctrl0_t cc2520_frmctrl0_default = {.f.autocrc = 1};

typedef union cc2520_txpower {
    uint8_t value;
    struct {
        unsigned pa_power: 8;
    } f;
} cc2520_txpower_t;

// Set 0dBm output power
static cc2520_txpower_t cc2520_txpower_default = { .f.pa_power = 0x32 };

typedef union cc2520_ccactrl0 {
    uint8_t value;
    struct {
        unsigned cca_thr: 8;
    } f;
} cc2520_ccactrl0_t;

// Raises CCA threshold from -108dBm to -8 - 76 = -84dBm
//static cc2520_ccactrl0_t cc2520_ccactrl0_default = { .f.cca_thr = 0xF8 };
// FIXME: This might be a problem in the EK devkit. But the threshold has to
// be really high!
// Raises CCA threshold from -108dBm to 10 - 76dBm
static cc2520_ccactrl0_t cc2520_ccactrl0_default = { .f.cca_thr = 0x1A };

typedef union cc2520_mdmctrl0 {
    uint8_t value;
    struct {
        unsigned tx_filter       : 1;
        unsigned preamble_length : 4;
        unsigned demod_avg_mode  : 1;
        unsigned dem_num_zeros   : 2;
    } f;
} cc2520_mdmctrl0_t;

// Makes sync word detection less likely by requiring two zero symbols before
// the sync word
static cc2520_mdmctrl0_t cc2520_mdmctrl0_default = {.f.tx_filter = 1, .f.preamble_length = 2, .f.demod_avg_mode = 0, .f.dem_num_zeros = 2};

typedef union cc2520_mdmctrl1 {
    uint8_t value;
    struct {
        unsigned corr_thr     : 5;
        unsigned corr_thr_sfd : 1;
        unsigned reserved0    : 2;
    } f;
} cc2520_mdmctrl1_t;

// Only one SFD symbol must be above threshold, and raise correlation
// threshold
static cc2520_mdmctrl1_t cc2520_mdmctrl1_default = {.f.corr_thr = 0x14, .f.corr_thr_sfd = 0};

typedef union cc2520_freqctrl {
    uint8_t value;
    struct {
        unsigned freq       : 7;
        unsigned reserved0  : 1;
    } f;
} cc2520_freqctrl_t;

static cc2520_freqctrl_t cc2520_freqctrl_default = {.f.freq = 0x0B };

typedef union cc2520_fifopctrl {
    uint8_t value;
    struct {
        unsigned fifop_thr : 7;
        unsigned reserved0 : 1;
    } f;
} cc2520_fifopctrl_t;

typedef union cc2520_frmfilt0 {
    uint8_t value;
    struct {
        unsigned frame_filter_en         : 1;
        unsigned pan_coordinator         : 1;
        unsigned max_frame_version       : 2;
        unsigned fcf_reserved_mask       : 3;
        unsigned reserved                : 1;
    } f;
} cc2520_frmfilt0_t;

static cc2520_frmfilt0_t cc2520_frmfilt0_default = {.f.max_frame_version = 2, .f.frame_filter_en = 1};

typedef union cc2520_frmfilt1 {
    uint8_t value;
    struct {
        unsigned reserved0               : 1;
        unsigned modify_ft_filter        : 2;
        unsigned accept_ft_0_beacon      : 1;
        unsigned accept_ft_1_data        : 1;
        unsigned accept_ft_2_ack         : 1;
        unsigned accept_ft_3_mac_cmd     : 1;
        unsigned accept_ft_4to7_reserved : 1;
    } f;
} cc2520_frmfilt1_t;

static cc2520_frmfilt1_t cc2520_frmfilt1_default = {.f.accept_ft_0_beacon = 1, .f.accept_ft_1_data = 1, .f.accept_ft_2_ack = 1, .f.accept_ft_3_mac_cmd = 1};

typedef union cc2520_srcmatch {
    uint8_t value;
    struct {
        unsigned src_match_en      : 1;
        unsigned autopend          : 1;
        unsigned pend_datareq_only : 1;
        unsigned reserved          : 5;
    } f;
} cc2520_srcmatch_t;

static cc2520_srcmatch_t cc2520_srcmatch_default = {.f.src_match_en = 1, .f.autopend = 1, .f.pend_datareq_only = 1};

typedef union cc2520_rxctrl {
    uint8_t value;
} cc2520_rxctrl_t;

static cc2520_rxctrl_t cc2520_rxctrl_default = {.value = 0x3F};

typedef union cc2520_fsctrl {
    uint8_t value;
} cc2520_fsctrl_t;

static cc2520_fsctrl_t cc2520_fsctrl_default = {.value = 0x5A};

typedef union cc2520_fscal1 {
    uint8_t value;
} cc2520_fscal1_t;

static cc2520_fscal1_t cc2520_fscal1_default = {.value = 0x2B};

typedef union cc2520_agcctrl1 {
    uint8_t value;
} cc2520_agcctrl1_t;

static cc2520_agcctrl1_t cc2520_agcctrl1_default = {.value = 0x11};

typedef union cc2520_adctest0 {
    uint8_t value;
} cc2520_adctest0_t;

static cc2520_adctest0_t cc2520_adctest0_default = {.value = 0x10};

typedef union cc2520_adctest1 {
    uint8_t value;
} cc2520_adctest1_t;

static cc2520_adctest1_t cc2520_adctest1_default = {.value = 0x0E};

typedef union cc2520_adctest2 {
    uint8_t value;
} cc2520_adctest2_t;

static cc2520_adctest2_t cc2520_adctest2_default = {.value = 0x03};

#ifndef CC2520_DEF_CHANNEL
#define CC2520_DEF_CHANNEL 26
#endif

#ifndef CC2520_DEF_RFPOWER
#define CC2520_DEF_RFPOWER 0x32 // 0 dBm
#endif

enum {
    CC2520_TX_PWR_MASK  = 0xFF,
    CC2520_TX_PWR_0     = 0x03, // -18 dBm
    CC2520_TX_PWR_1     = 0x2C, //  -7 dBm
    CC2520_TX_PWR_2     = 0x88, //  -4 dBm
    CC2520_TX_PWR_3     = 0x81, //  -2 dBm
    CC2520_TX_PWR_4     = 0x32, //   0 dBm
    CC2520_TX_PWR_5     = 0x13, //   1 dBm
    CC2520_TX_PWR_6     = 0xAB, //   2 dBm
    CC2520_TX_PWR_7     = 0xF2, //   3 dBm
    CC2520_TX_PWR_8     = 0xF7, //   5 dBm
    CC2520_CHANNEL_MASK = 0x1F,
};

enum cc2520_register_enums
{
    // FREG Registers
    CC2520_FRMFILT0     = 0x00,
    CC2520_FRMFILT1     = 0x01,
    CC2520_SRCMATCH     = 0x02,
    CC2520_SRCSHORTEN0  = 0x04,
    CC2520_SRCSHORTEN1  = 0x05,
    CC2520_SRCSHORTEN2  = 0x06,
    CC2520_SRCEXTEN0    = 0x08,
    CC2520_SRCEXTEN1    = 0x09,
    CC2520_SRCEXTEN2    = 0x0A,
    CC2520_FRMCTRL0     = 0x0C,
    CC2520_FRMCTRL1     = 0x0D,
    CC2520_RXENABLE0    = 0x0E,
    CC2520_RXENABLE1    = 0x0F,
    CC2520_EXCFLAG0     = 0x10,
    CC2520_EXCFLAG1     = 0x11,
    CC2520_EXCFLAG2     = 0x12,
    CC2520_EXCMASKA0    = 0x14,
    CC2520_EXCMASKA1    = 0x15,
    CC2520_EXCMASKA2    = 0x16,
    CC2520_EXCMASKB0    = 0x18,
    CC2520_EXCMASKB1    = 0x19,
    CC2520_EXCMASKB2    = 0x1A,
    CC2520_EXCBINDX0    = 0x1C,
    CC2520_EXCBINDX1    = 0x1D,
    CC2520_EXCBINDY0    = 0x1E,
    CC2520_EXCBINDY1    = 0x1F,
    CC2520_GPIOCTRL0    = 0x20,
    CC2520_GPIOCTRL1    = 0x21,
    CC2520_GPIOCTRL2    = 0x22,
    CC2520_GPIOCTRL3    = 0x23,
    CC2520_GPIOCTRL4    = 0x24,
    CC2520_GPIOCTRL5    = 0x25,
    CC2520_GPIOPOLARITY = 0x26,
    CC2520_GPIOCTRL     = 0x28,
    CC2520_DPUCON       = 0x2A,
    CC2520_DPUSTAT      = 0x2C,
    CC2520_FREQCTRL     = 0x2E,
    CC2520_FREQTUNE     = 0x2F,
    CC2520_TXPOWER      = 0x30,
    CC2520_TXCTRL       = 0x31,
    CC2520_FSMSTAT0     = 0x32,
    CC2520_FSMSTAT1     = 0x33,
    CC2520_FIFOPCTRL    = 0x34,
    CC2520_FSMCTRL      = 0x35,
    CC2520_CCACTRL0     = 0x36,
    CC2520_CCACTRL1     = 0x37,
    CC2520_RSSI         = 0x38,
    CC2520_RSSISTAT     = 0x39,
    CC2520_RXFIRST      = 0x3C,
    CC2520_RXFIFOCNT    = 0x3E,
    CC2520_TXFIFOCNT    = 0x3F,

    // SREG registers
    CC2520_CHIPID       = 0x40,
    CC2520_VERSION      = 0x42,
    CC2520_EXTCLOCK     = 0x44,
    CC2520_MDMCTRL0     = 0x46,
    CC2520_MDMCTRL1     = 0x47,
    CC2520_FREQEST      = 0x48,
    CC2520_RXCTRL       = 0x4A,
    CC2520_FSCTRL       = 0x4C,
    CC2520_FSCAL0       = 0x4E,
    CC2520_FSCAL1       = 0x4F,
    CC2520_FSCAL2       = 0x50,
    CC2520_FSCAL3       = 0x51,
    CC2520_AGCCTRL0     = 0x52,
    CC2520_AGCCTRL1     = 0x53,
    CC2520_AGCCTRL2     = 0x54,
    CC2520_AGCCTRL3     = 0x55,
    CC2520_ADCTEST0     = 0x56,
    CC2520_ADCTEST1     = 0x57,
    CC2520_ADCTEST2     = 0x58,
    CC2520_MDMTEST0     = 0x5A,
    CC2520_MDMTEST1     = 0x5B,
    CC2520_DACTEST0     = 0x5C,
    CC2520_DACTEST1     = 0x5D,
    CC2520_ATEST        = 0x5E,
    CC2520_DACTEST2     = 0x5F,
    CC2520_PTEST0       = 0x60,
    CC2520_PTEST1       = 0x61,
    CC2520_RESERVED     = 0x62,
    CC2520_DPUBIST      = 0x7A,
    CC2520_ACTBIST      = 0x7C,
    CC2520_RAMBIST      = 0x7E,
};

enum cc2520_spi_command_enums
{
    CC2520_CMD_SNOP           = 0x00, //
    CC2520_CMD_IBUFLD         = 0x02, //
    CC2520_CMD_SIBUFEX        = 0x03, //
    CC2520_CMD_SSAMPLECCA     = 0x04, //
    CC2520_CMD_SRES           = 0x0f, //
    CC2520_CMD_MEMORY_MASK    = 0x0f, //
    CC2520_CMD_MEMORY_READ    = 0x10, // MEMRD
    CC2520_CMD_MEMORY_WRITE   = 0x20, // MEMWR
    CC2520_CMD_RXBUF          = 0x30, //
    CC2520_CMD_RXBUFCP        = 0x38, //
    CC2520_CMD_RXBUFMOV       = 0x32, //
    CC2520_CMD_TXBUF          = 0x3A, //
    CC2520_CMD_TXBUFCP        = 0x3E, //
    CC2520_CMD_RANDOM         = 0x3C, //
    CC2520_CMD_SXOSCON        = 0x40, //
    CC2520_CMD_STXCAL         = 0x41, //
    CC2520_CMD_SRXON          = 0x42, //
    CC2520_CMD_STXON          = 0x43, //
    CC2520_CMD_STXONCCA       = 0x44, //
    CC2520_CMD_SRFOFF         = 0x45, //
    CC2520_CMD_SXOSCOFF        = 0x46, //
    CC2520_CMD_SFLUSHRX       = 0x47, //
    CC2520_CMD_SFLUSHTX       = 0x48, //
    CC2520_CMD_SACK           = 0x49, //
    CC2520_CMD_SACKPEND       = 0x4A, //
    CC2520_CMD_SNACK          = 0x4B, //
    CC2520_CMD_SRXMASKBITSET  = 0x4C, //
    CC2520_CMD_SRXMASKBITCLR  = 0x4D, //
    CC2520_CMD_RXMASKAND      = 0x4E, //
    CC2520_CMD_RXMASKOR       = 0x4F, //
    CC2520_CMD_MEMCP          = 0x50, //
    CC2520_CMD_MEMCPR         = 0x52, //
    CC2520_CMD_MEMXCP         = 0x54, //
    CC2520_CMD_MEMXWR         = 0x56, //
    CC2520_CMD_BCLR           = 0x58, //
    CC2520_CMD_BSET           = 0x59, //
    CC2520_CMD_CTR_UCTR       = 0x60, //
    CC2520_CMD_CBCMAC         = 0x64, //
    CC2520_CMD_UCBCMAC        = 0x66, //
    CC2520_CMD_CCM            = 0x68, //
    CC2520_CMD_UCCM           = 0x6A, //
    CC2520_CMD_ECB            = 0x70, //
    CC2520_CMD_ECBO           = 0x72, //
    CC2520_CMD_ECBX           = 0x74, //
    CC2520_CMD_INC            = 0x78, //
    CC2520_CMD_ABORT          = 0x7F, //
    CC2520_CMD_REGISTER_READ  = 0x80, //
    CC2520_CMD_REGISTER_WRITE = 0xC0, //
};

#endif // __CC2520XDRIVERLAYER_H__
