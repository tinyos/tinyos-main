/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */
 
#ifndef __CC2420XDRIVERLAYER_H__
#define __CC2420XDRIVERLAYER_H__


typedef nx_struct cc2420x_header_t
{
	nxle_uint8_t length;
} cc2420x_header_t;

typedef struct cc2420x_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	}__attribute__((packed)); 
} __attribute__((packed)) cc2420x_metadata_t; 

enum cc2420X_timing_enums {
	CC2420X_SYMBOL_TIME = 16, // 16us	
	IDLE_2_RX_ON_TIME = 12 * CC2420X_SYMBOL_TIME, 
	PD_2_IDLE_TIME = 860, // .86ms
	STROBE_TO_TX_ON_TIME = 12 * CC2420X_SYMBOL_TIME, 
	// TX SFD delay is computed as follows:
	// a.) STROBE_TO_TX_ON_TIME is required for preamble transmission to 
	// start after TX strobe is issued
	// b.) the SFD byte is the 5th byte transmitted (10 symbol periods)
	// c.) there's approximately a 25us delay between the strobe and reading
	// the timer register
	TX_SFD_DELAY = STROBE_TO_TX_ON_TIME + 10 * CC2420X_SYMBOL_TIME - 25,
	// TX SFD is captured in hardware
	RX_SFD_DELAY = 0,
};

enum cc2420X_reg_access_enums {
	CC2420X_CMD_REGISTER_MASK = 0x3f,
	CC2420X_CMD_REGISTER_READ = 0x40,
	CC2420X_CMD_REGISTER_WRITE = 0x00,
	CC2420X_CMD_TXRAM_WRITE	= 0x80,
};

typedef union cc2420X_status {
	uint16_t value;
	struct {
	  unsigned  reserved0:1;
	  unsigned  rssi_valid:1;
	  unsigned  lock:1;
	  unsigned  tx_active:1;
	  
	  unsigned  enc_busy:1;
	  unsigned  tx_underflow:1;
	  unsigned  xosc16m_stable:1;
	  unsigned  reserved7:1;
	};
} cc2420X_status_t;

typedef union cc2420X_iocfg0 {
	uint16_t value;
	struct {
	  unsigned  fifop_thr:7;
	  unsigned  cca_polarity:1;
	  unsigned  sfd_polarity:1;
	  unsigned  fifop_polarity:1;
	  unsigned  fifo_polarity:1;
	  unsigned  bcn_accept:1;
	  unsigned  reserved:4; // write as 0
	} f;
} cc2420X_iocfg0_t;

// TODO: make sure that we avoid wasting RAM
static const cc2420X_iocfg0_t cc2420X_iocfg0_default = {.f.fifop_thr = 64, .f.cca_polarity = 0, .f.sfd_polarity = 0, .f.fifop_polarity = 0, .f.fifo_polarity = 0, .f.bcn_accept = 0, .f.reserved = 0};

typedef union cc2420X_iocfg1 {
	uint16_t value;
	struct {
	  unsigned  ccamux:5;
	  unsigned  sfdmux:5;
	  unsigned  hssd_src:3;
	  unsigned  reserved:3; // write as 0
	} f;
} cc2420X_iocfg1_t;

static const cc2420X_iocfg1_t cc2420X_iocfg1_default = {.value = 0};

typedef union cc2420X_fsctrl {
	uint16_t value;
	struct {
	  unsigned  freq:10;
	  unsigned  lock_status:1;
	  unsigned  lock_length:1;
	  unsigned  cal_running:1;
	  unsigned  cal_done:1;
	  unsigned  lock_thr:2;
	} f;
} cc2420X_fsctrl_t;

static const cc2420X_fsctrl_t cc2420X_fsctrl_default = {.f.lock_thr = 1, .f.freq = 357, .f.lock_status = 0, .f.lock_length = 0, .f.cal_running = 0, .f.cal_done = 0};

typedef union cc2420X_mdmctrl0 {
	uint16_t value;
	struct {
	  unsigned  preamble_length:4;
	  unsigned  autoack:1;
	  unsigned  autocrc:1;
	  unsigned  cca_mode:2;
	  unsigned  cca_hyst:3;
	  unsigned  adr_decode:1;
	  unsigned  pan_coordinator:1;
	  unsigned  reserved_frame_mode:1;
	  unsigned  reserved:2;
	} f;
} cc2420X_mdmctrl0_t;

static const cc2420X_mdmctrl0_t cc2420X_mdmctrl0_default = {.f.preamble_length = 2, .f.autocrc = 1, .f.cca_mode = 3, .f.cca_hyst = 2, .f.adr_decode = 1};

typedef union cc2420X_txctrl {
	uint16_t value;
	struct {
	  unsigned  pa_level:5;
	  unsigned reserved:1;
	  unsigned pa_current:3;
	  unsigned txmix_current:2;
	  unsigned txmix_caparray:2;
  	  unsigned tx_turnaround:1;
  	  unsigned txmixbuf_cur:2;
	} f;
} cc2420X_txctrl_t;

static const cc2420X_txctrl_t cc2420X_txctrl_default = {.f.pa_level = 31, .f.reserved = 1, .f.pa_current = 3, .f.tx_turnaround = 1, .f.txmixbuf_cur = 2};


#ifndef CC2420X_DEF_CHANNEL
#define CC2420X_DEF_CHANNEL 26
#endif

#ifndef CC2420X_DEF_RFPOWER
#define CC2420X_DEF_RFPOWER 31
#endif

enum {
	CC2420X_TX_PWR_MASK = 0x1f,
	CC2420X_CHANNEL_MASK = 0x1f,
};

enum cc2420X_config_reg_enums {
  CC2420X_SNOP = 0x00,
  CC2420X_SXOSCON = 0x01,
  CC2420X_STXCAL = 0x02,
  CC2420X_SRXON = 0x03,
  CC2420X_STXON = 0x04,
  CC2420X_STXONCCA = 0x05,
  CC2420X_SRFOFF = 0x06,
  CC2420X_SXOSCOFF = 0x07,
  CC2420X_SFLUSHRX = 0x08,
  CC2420X_SFLUSHTX = 0x09,
  CC2420X_SACK = 0x0a,
  CC2420X_SACKPEND = 0x0b,
  CC2420X_SRXDEC = 0x0c,
  CC2420X_STXENC = 0x0d,
  CC2420X_SAES = 0x0e,
  CC2420X_MAIN = 0x10,
  CC2420X_MDMCTRL0 = 0x11,
  CC2420X_MDMCTRL1 = 0x12,
  CC2420X_RSSI = 0x13,
  CC2420X_SYNCWORD = 0x14,
  CC2420X_TXCTRL = 0x15,
  CC2420X_RXCTRL0 = 0x16,
  CC2420X_RXCTRL1 = 0x17,
  CC2420X_FSCTRL = 0x18,
  CC2420X_SECCTRL0 = 0x19,
  CC2420X_SECCTRL1 = 0x1a,
  CC2420X_BATTMON = 0x1b,
  CC2420X_IOCFG0 = 0x1c,
  CC2420X_IOCFG1 = 0x1d,
  CC2420X_MANFIDL = 0x1e,
  CC2420X_MANFIDH = 0x1f,
  CC2420X_FSMTC = 0x20,
  CC2420X_MANAND = 0x21,
  CC2420X_MANOR = 0x22,
  CC2420X_AGCCTRL = 0x23,
  CC2420X_AGCTST0 = 0x24,
  CC2420X_AGCTST1 = 0x25,
  CC2420X_AGCTST2 = 0x26,
  CC2420X_FSTST0 = 0x27,
  CC2420X_FSTST1 = 0x28,
  CC2420X_FSTST2 = 0x29,
  CC2420X_FSTST3 = 0x2a,
  CC2420X_RXBPFTST = 0x2b,
  CC2420X_FSMSTATE = 0x2c,
  CC2420X_ADCTST = 0x2d,
  CC2420X_DACTST = 0x2e,
  CC2420X_TOPTST = 0x2f,
  CC2420X_TXFIFO = 0x3e,
  CC2420X_RXFIFO = 0x3f,
};

enum cc2420X_ram_addr_enums {
  CC2420X_RAM_TXFIFO = 0x000,
  CC2420X_RAM_TXFIFO_END = 0x7f,  
  CC2420X_RAM_RXFIFO = 0x080,
  CC2420X_RAM_KEY0 = 0x100,
  CC2420X_RAM_RXNONCE = 0x110,
  CC2420X_RAM_SABUF = 0x120,
  CC2420X_RAM_KEY1 = 0x130,
  CC2420X_RAM_TXNONCE = 0x140,
  CC2420X_RAM_CBCSTATE = 0x150,
  CC2420X_RAM_IEEEADR = 0x160,
  CC2420X_RAM_PANID = 0x168,
  CC2420X_RAM_SHORTADR = 0x16a,
};


#endif // __CC2420XDRIVERLAYER_H__
