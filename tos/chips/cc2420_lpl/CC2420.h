/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:30:52 $
 */

#ifndef __CC2420_H__
#define __CC2420_H__

//#include "message.h"

typedef uint8_t cc2420_status_t;

typedef nx_struct cc2420_header_t {
  nxle_uint8_t length;
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  nxle_uint16_t destpan;
  nxle_uint16_t dest;
  nxle_uint16_t src;
  nxle_uint8_t type;
} cc2420_header_t;

typedef nx_struct cc2420_footer_t {
} cc2420_footer_t;

typedef nx_struct cc2420_metadata_t {
  nx_uint8_t tx_power;
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_bool crc;
  nx_bool ack;
  nx_uint16_t time;
  nx_uint16_t rxInterval;
} cc2420_metadata_t;

typedef nx_struct cc2420_packet_t {
  cc2420_header_t packet;
  nx_uint8_t data[];
} cc2420_packet_t;

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 28
#endif

#ifndef CC2420_DEF_CHANNEL
#define CC2420_DEF_CHANNEL 26
#endif

#ifndef CC2420_DEF_RFPOWER
#define CC2420_DEF_RFPOWER 31
#endif

enum {
  // size of the header not including the length byte
  MAC_HEADER_SIZE = sizeof( cc2420_header_t ) - 1,
  // size of the footer (FCS field)
  MAC_FOOTER_SIZE = sizeof( uint16_t ),
  // MDU
  MAC_PACKET_SIZE = MAC_HEADER_SIZE + TOSH_DATA_LENGTH + MAC_FOOTER_SIZE,
};

enum cc2420_enums {
  CC2420_TIME_ACK_TURNAROUND = 7, // jiffies
  CC2420_TIME_VREN = 20,          // jiffies
  CC2420_TIME_SYMBOL = 2,         // 2 symbols / jiffy
  CC2420_BACKOFF_PERIOD = ( 20 / CC2420_TIME_SYMBOL ), // symbols
  CC2420_MIN_BACKOFF = ( 20 / CC2420_TIME_SYMBOL ),  // platform specific?
  CC2420_ACK_WAIT_DELAY = 128,    // jiffies
};

enum cc2420_status_enums {
  CC2420_STATUS_RSSI_VALID = 1 << 1,
  CC2420_STATUS_LOCK = 1 << 2,
  CC2420_STATUS_TX_ACTIVE = 1 << 3,
  CC2420_STATUS_ENC_BUSY = 1 << 4,
  CC2420_STATUS_TX_UNDERFLOW = 1 << 5,
  CC2420_STATUS_XOSC16M_STABLE = 1 << 6,
};

enum cc2420_config_reg_enums {
  CC2420_SNOP = 0x00,
  CC2420_SXOSCON = 0x01,
  CC2420_STXCAL = 0x02,
  CC2420_SRXON = 0x03,
  CC2420_STXON = 0x04,
  CC2420_STXONCCA = 0x05,
  CC2420_SRFOFF = 0x06,
  CC2420_SXOSCOFF = 0x07,
  CC2420_SFLUSHRX = 0x08,
  CC2420_SFLUSHTX = 0x09,
  CC2420_SACK = 0x0a,
  CC2420_SACKPEND = 0x0b,
  CC2420_SRXDEC = 0x0c,
  CC2420_SRXENC = 0x0d,
  CC2420_SAES = 0x0e,
  CC2420_MAIN = 0x10,
  CC2420_MDMCTRL0 = 0x11,
  CC2420_MDMCTRL1 = 0x12,
  CC2420_RSSI = 0x13,
  CC2420_SYNCWORD = 0x14,
  CC2420_TXCTRL = 0x15,
  CC2420_RXCTRL0 = 0x16,
  CC2420_RXCTRL1 = 0x17,
  CC2420_FSCTRL = 0x18,
  CC2420_SECCTRL0 = 0x19,
  CC2420_SECCTRL1 = 0x1a,
  CC2420_BATTMON = 0x1b,
  CC2420_IOCFG0 = 0x1c,
  CC2420_IOCFG1 = 0x1d,
  CC2420_MANFIDL = 0x1e,
  CC2420_MANFIDH = 0x1f,
  CC2420_FSMTC = 0x20,
  CC2420_MANAND = 0x21,
  CC2420_MANOR = 0x22,
  CC2420_AGCCTRL = 0x23,
  CC2420_AGCTST0 = 0x24,
  CC2420_AGCTST1 = 0x25,
  CC2420_AGCTST2 = 0x26,
  CC2420_FSTST0 = 0x27,
  CC2420_FSTST1 = 0x28,
  CC2420_FSTST2 = 0x29,
  CC2420_FSTST3 = 0x2a,
  CC2420_RXBPFTST = 0x2b,
  CC2420_FMSTATE = 0x2c,
  CC2420_ADCTST = 0x2d,
  CC2420_DACTST = 0x2e,
  CC2420_TOPTST = 0x2f,
  CC2420_TXFIFO = 0x3e,
  CC2420_RXFIFO = 0x3f,
};

enum cc2420_ram_addr_enums {
  CC2420_RAM_TXFIFO = 0x000,
  CC2420_RAM_RXFIFO = 0x080,
  CC2420_RAM_KEY0 = 0x100,
  CC2420_RAM_RXNONCE = 0x110,
  CC2420_RAM_SABUF = 0x120,
  CC2420_RAM_KEY1 = 0x130,
  CC2420_RAM_TXNONCE = 0x140,
  CC2420_RAM_CBCSTATE = 0x150,
  CC2420_RAM_IEEEADR = 0x160,
  CC2420_RAM_PANID = 0x168,
  CC2420_RAM_SHORTADR = 0x16a,
};

enum cc2420_nonce_enums {
  CC2420_NONCE_BLOCK_COUNTER = 0,
  CC2420_NONCE_KEY_SEQ_COUNTER = 2,
  CC2420_NONCE_FRAME_COUNTER = 3,
  CC2420_NONCE_SOURCE_ADDRESS = 7,
  CC2420_NONCE_FLAGS = 15,
};

enum cc2420_main_enums {
  CC2420_MAIN_RESETn = 15,
  CC2420_MAIN_ENC_RESETn = 14,
  CC2420_MAIN_DEMOD_RESETn = 13,
  CC2420_MAIN_MOD_RESETn = 12,
  CC2420_MAIN_FS_RESETn = 11,
  CC2420_MAIN_XOSC16M_BYPASS = 0,
};

enum cc2420_mdmctrl0_enums {
  CC2420_MDMCTRL0_RESERVED_FRAME_MODE = 13,
  CC2420_MDMCTRL0_PAN_COORDINATOR = 12,
  CC2420_MDMCTRL0_ADR_DECODE = 11,
  CC2420_MDMCTRL0_CCA_HYST = 8,
  CC2420_MDMCTRL0_CCA_MOD = 6,
  CC2420_MDMCTRL0_AUTOCRC = 5,
  CC2420_MDMCTRL0_AUTOACK = 4,
  CC2420_MDMCTRL0_PREAMBLE_LENGTH = 0,
};

enum cc2420_mdmctrl1_enums {
  CC2420_MDMCTRL1_CORR_THR = 6,
  CC2420_MDMCTRL1_DEMOD_AVG_MODE = 5,
  CC2420_MDMCTRL1_MODULATION_MODE = 4,
  CC2420_MDMCTRL1_TX_MODE = 2,
  CC2420_MDMCTRL1_RX_MODE = 0,
};

enum cc2420_rssi_enums {
  CC2420_RSSI_CCA_THR = 8,
  CC2420_RSSI_RSSI_VAL = 0,
};

enum cc2420_syncword_enums {
  CC2420_SYNCWORD_SYNCWORD = 0,
};

enum cc2420_txctrl_enums {
  CC2420_TXCTRL_TXMIXBUF_CUR = 14,
  CC2420_TXCTRL_TX_TURNAROUND = 13,
  CC2420_TXCTRL_TXMIX_CAP_ARRAY = 11,
  CC2420_TXCTRL_TXMIX_CURRENT = 9,
  CC2420_TXCTRL_PA_CURRENT = 6,
  CC2420_TXCTRL_RESERVED = 5,
  CC2420_TXCTRL_PA_LEVEL = 0,
};

enum cc2420_rxctrl0_enums {
  CC2420_RXCTRL0_RXMIXBUF_CUR = 12,
  CC2420_RXCTRL0_HIGH_LNA_GAIN = 10,
  CC2420_RXCTRL0_MED_LNA_GAIN = 8,
  CC2420_RXCTRL0_LOW_LNA_GAIN = 6,
  CC2420_RXCTRL0_HIGH_LNA_CURRENT = 4,
  CC2420_RXCTRL0_MED_LNA_CURRENT = 2,
  CC2420_RXCTRL0_LOW_LNA_CURRENT = 0,
};

enum cc2420_rxctrl1_enums {
  CC2420_RXCTRL1_RXBPF_LOCUR = 13,
  CC2420_RXCTRL1_RXBPF_MIDCUR = 12,
  CC2420_RXCTRL1_LOW_LOWGAIN = 11,
  CC2420_RXCTRL1_MED_LOWGAIN = 10,
  CC2420_RXCTRL1_HIGH_HGM = 9,
  CC2420_RXCTRL1_MED_HGM = 8,
  CC2420_RXCTRL1_LNA_CAP_ARRAY = 6,
  CC2420_RXCTRL1_RXMIX_TAIL = 4,
  CC2420_RXCTRL1_RXMIX_VCM = 2,
  CC2420_RXCTRL1_RXMIX_CURRENT = 0,
};

enum cc2420_rsctrl_enums {
  CC2420_FSCTRL_LOCK_THR = 14,
  CC2420_FSCTRL_CAL_DONE = 13,
  CC2420_FSCTRL_CAL_RUNNING = 12,
  CC2420_FSCTRL_LOCK_LENGTH = 11,
  CC2420_FSCTRL_LOCK_STATUS = 10,
  CC2420_FSCTRL_FREQ = 0,
};

enum cc2420_secctrl0_enums {
  CC2420_SECCTRL0_RXFIFO_PROTECTION = 9,
  CC2420_SECCTRL0_SEC_CBC_HEAD = 8,
  CC2420_SECCTRL0_SEC_SAKEYSEL = 7,
  CC2420_SECCTRL0_SEC_TXKEYSEL = 6,
  CC2420_SECCTRL0_SEC_RXKEYSEL = 5,
  CC2420_SECCTRL0_SEC_M = 2,
  CC2420_SECCTRL0_SEC_MODE = 0,
};

enum cc2420_secctrl1_enums {
  CC2420_SECCTRL1_SEC_TXL = 8,
  CC2420_SECCTRL1_SEC_RXL = 0,
};

enum cc2420_battmon_enums {
  CC2420_BATTMON_BATT_OK = 6,
  CC2420_BATTMON_BATTMON_EN = 5,
  CC2420_BATTMON_BATTMON_VOLTAGE = 0,
};

enum cc2420_iocfg0_enums {
  CC2420_IOCFG0_BCN_ACCEPT = 11,
  CC2420_IOCFG0_FIFO_POLARITY = 10,
  CC2420_IOCFG0_FIFOP_POLARITY = 9,
  CC2420_IOCFG0_SFD_POLARITY = 8,
  CC2420_IOCFG0_CCA_POLARITY = 7,
  CC2420_IOCFG0_FIFOP_THR = 0,
};

enum cc2420_iocfg1_enums {
  CC2420_IOCFG1_HSSD_SRC = 10,
  CC2420_IOCFG1_SFDMUX = 5,
  CC2420_IOCFG1_CCAMUX = 0,
};

enum cc2420_manfidl_enums {
  CC2420_MANFIDL_PARTNUM = 12,
  CC2420_MANFIDL_MANFID = 0,
};

enum cc2420_manfidh_enums {
  CC2420_MANFIDH_VERSION = 12,
  CC2420_MANFIDH_PARTNUM = 0,
};

enum cc2420_fsmtc_enums {
  CC2420_FSMTC_TC_RXCHAIN2RX = 13,
  CC2420_FSMTC_TC_SWITCH2TX = 10,
  CC2420_FSMTC_TC_PAON2TX = 6,
  CC2420_FSMTC_TC_TXEND2SWITCH = 3,
  CC2420_FSMTC_TC_TXEND2PAOFF = 0,
};

enum cc2420_sfdmux_enums {
  CC2420_SFDMUX_SFD = 0,
  CC2420_SFDMUX_XOSC16M_STABLE = 24,
};

#endif
