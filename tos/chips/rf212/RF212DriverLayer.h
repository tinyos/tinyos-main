/*
 * Copyright (c) 2007, Vanderbilt University
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
 * Author: Miklos Maroti
 */

#ifndef __RF212DRIVERLAYER_H__
#define __RF212DRIVERLAYER_H__

typedef nx_struct rf212_header_t
{
	nxle_uint8_t length;
} rf212_header_t;

typedef struct rf212_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	}__attribute__((packed));
} __attribute__((packed)) rf212_metadata_t;

enum rf212_registers_enum
{
	RF212_TRX_STATUS = 0x01,
	RF212_TRX_STATE = 0x02,
	RF212_TRX_CTRL_0 = 0x03,
	RF212_TRX_CTRL_1 = 0x04,
	RF212_PHY_TX_PWR = 0x05,
	RF212_PHY_RSSI = 0x06,
	RF212_PHY_ED_LEVEL = 0x07,
	RF212_PHY_CC_CCA = 0x08,
	RF212_CCA_THRES = 0x09,
	RF212_TRX_CTRL_2 = 0x0C,
	RF212_IRQ_MASK = 0x0E,
	RF212_IRQ_STATUS = 0x0F,
	RF212_VREG_CTRL = 0x10,
	RF212_BATMON = 0x11,
	RF212_XOSC_CTRL = 0x12,
	RF212_PLL_CF = 0x1A,
	RF212_PLL_DCU = 0x1B,
	RF212_PART_NUM = 0x1C,
	RF212_VERSION_NUM = 0x1D,
	RF212_MAN_ID_0 = 0x1E,
	RF212_MAN_ID_1 = 0x1F,
	RF212_SHORT_ADDR_0 = 0x20,
	RF212_SHORT_ADDR_1 = 0x21,
	RF212_PAN_ID_0 = 0x22,
	RF212_PAN_ID_1 = 0x23,
	RF212_IEEE_ADDR_0 = 0x24,
	RF212_IEEE_ADDR_1 = 0x25,
	RF212_IEEE_ADDR_2 = 0x26,
	RF212_IEEE_ADDR_3 = 0x27,
	RF212_IEEE_ADDR_4 = 0x28,
	RF212_IEEE_ADDR_5 = 0x29,
	RF212_IEEE_ADDR_6 = 0x2A,
	RF212_IEEE_ADDR_7 = 0x2B,
	RF212_XAH_CTRL = 0x2C,
	RF212_CSMA_SEED_0 = 0x2D,
	RF212_CSMA_SEED_1 = 0x2E,
};

enum rf212_trx_status_enums
{
	RF212_CCA_DONE = 1 << 7,
	RF212_CCA_STATUS = 1 << 6,
	RF212_TRX_STATUS_MASK = 0x1F,
	RF212_P_ON = 0,
	RF212_BUSY_RX = 1,
	RF212_BUSY_TX = 2,
	RF212_RX_ON = 6,
	RF212_TRX_OFF = 8,
	RF212_PLL_ON = 9,
	RF212_SLEEP = 15,
	RF212_BUSY_RX_AACK = 17,
	RF212_BUSR_TX_ARET = 18,
	RF212_RX_AACK_ON = 22,
	RF212_TX_ARET_ON = 25,
	RF212_RX_ON_NOCLK = 28,
	RF212_AACK_ON_NOCLK = 29,
	RF212_BUSY_RX_AACK_NOCLK = 30,
	RF212_STATE_TRANSITION_IN_PROGRESS = 31,
};

enum rf212_trx_state_enums
{
	RF212_TRAC_STATUS_MASK = 0xE0,
	RF212_TRAC_SUCCESS = 0,
	RF212_TRAC_SUCCESS_DATA_PENDING = 1 << 5,
	RF212_TRAC_SUCCESS_WAIT_FOR_ACK = 2 << 5,
	RF212_TRAC_CHANNEL_ACCESS_FAILURE = 3 << 5,
	RF212_TRAC_NO_ACK = 5 << 5,
	RF212_TRAC_INVALID = 7 << 5,
	RF212_TRX_CMD_MASK = 0x1F,
	RF212_NOP = 0,
	RF212_TX_START = 2,
	RF212_FORCE_TRX_OFF = 3,
};

enum rf212_trx_data_modes
{
	RF212_DATA_MODE_BPSK_20 = 0x00,
	RF212_DATA_MODE_BPSK_40 = 0x04,
	RF212_DATA_MODE_OQPSK_SIN_RC_100 = 0x08,
	RF212_DATA_MODE_OQPSK_SIN_RC_200 = 0x09,
	RF212_DATA_MODE_OQPSK_SIN_RC_400_SCR = 0x2A,
	RF212_DATA_MODE_OQPSK_SIN_RC_400 = 0x0A,
	RF212_DATA_MODE_OQPSK_SIN_250 = 0x0C,
	RF212_DATA_MODE_OQPSK_SIN_500 = 0x0D,
	RF212_DATA_MODE_OQPSK_SIN_1000_SCR = 0x2E,
	RF212_DATA_MODE_OQPSK_SIN_1000 = 0x0E,
	RF212_DATA_MODE_OQPSK_RC_250 = 0x1C,
	RF212_DATA_MODE_OQPSK_RC_500 = 0x1D,
	RF212_DATA_MODE_OQPSK_RC_1000_SCR = 0x3E,
	RF212_DATA_MODE_OQPSK_RC_1000 = 0x1E,

	//register default is PHY mode BPSK-40
	//with OQPSK_SCRAM_EN set to 1
	RF212_DATA_MODE_DEFAULT = 0x24,
};

enum rf212_phy_rssi_enums
{
	RF212_RX_CRC_VALID = 1 << 7,
	RF212_RSSI_MASK = 0x1F,
};

enum rf212_phy_cc_cca_enums
{
	RF212_CCA_REQUEST = 1 << 7,
	RF212_CCA_MODE_0 = 0 << 5,
	RF212_CCA_MODE_1 = 1 << 5,
	RF212_CCA_MODE_2 = 2 << 5,
	RF212_CCA_MODE_3 = 3 << 5,
	RF212_CHANNEL_MASK = 0x1F,
};

enum rf212_irq_register_enums
{
	RF212_IRQ_BAT_LOW = 1 << 7,
	RF212_IRQ_TRX_UR = 1 << 6,
	RF212_IRQ_AMI = 1 << 5,
	RF212_IRQ_CCA_ED_DONE = 1 << 4,
	RF212_IRQ_TRX_END = 1 << 3,
	RF212_IRQ_RX_START = 1 << 2,
	RF212_IRQ_PLL_UNLOCK = 1 << 1,
	RF212_IRQ_PLL_LOCK = 1 << 0,
};

enum rf212_batmon_enums
{
	RF212_BATMON_OK = 1 << 5,
	RF212_BATMON_VHR = 1 << 4,
	RF212_BATMON_VTH_MASK = 0x0F,
};

enum rf212_vreg_ctrl_enums
{
	RF212_AVREG_EXT = 1 << 7,
	RF212_AVDD_OK = 1 << 6,
	RF212_DVREG_EXT = 1 << 3,
	RF212_DVDD_OK = 1 << 2,
};

enum rf212_xosc_ctrl_enums
{
	RF212_XTAL_MODE_OFF = 0 << 4,
	RF212_XTAL_MODE_EXTERNAL = 4 << 4,
	RF212_XTAL_MODE_INTERNAL = 15 << 4,
};

enum rf212_spi_command_enums
{
	RF212_CMD_REGISTER_READ = 0x80,
	RF212_CMD_REGISTER_WRITE = 0xC0,
	RF212_CMD_REGISTER_MASK = 0x3F,
	RF212_CMD_FRAME_READ = 0x20,
	RF212_CMD_FRAME_WRITE = 0x60,
	RF212_CMD_SRAM_READ = 0x00,
	RF212_CMD_SRAM_WRITE = 0x40,
};

#endif//__RF212DRIVERLAYER_H__
