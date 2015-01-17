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

#ifndef __RF230DRIVERLAYER_H__
#define __RF230DRIVERLAYER_H__

typedef nx_struct rf230_header_t
{
	nxle_uint8_t length;
} rf230_header_t;

typedef struct rf230_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	}__attribute__((packed));
} __attribute__((packed)) rf230_metadata_t;

enum rf230_registers_enum
{
	RF230_TRX_STATUS = 0x01,
	RF230_TRX_STATE = 0x02,
	RF230_TRX_CTRL_0 = 0x03,
	RF230_PHY_TX_PWR = 0x05,
	RF230_PHY_RSSI = 0x06,
	RF230_PHY_ED_LEVEL = 0x07,
	RF230_PHY_CC_CCA = 0x08,
	RF230_CCA_THRES = 0x09,
	RF230_IRQ_MASK = 0x0E,
	RF230_IRQ_STATUS = 0x0F,
	RF230_VREG_CTRL = 0x10,
	RF230_BATMON = 0x11,
	RF230_XOSC_CTRL = 0x12,
	RF230_PLL_CF = 0x1A,
	RF230_PLL_DCU = 0x1B,
	RF230_PART_NUM = 0x1C,
	RF230_VERSION_NUM = 0x1D,
	RF230_MAN_ID_0 = 0x1E,
	RF230_MAN_ID_1 = 0x1F,
	RF230_SHORT_ADDR_0 = 0x20,
	RF230_SHORT_ADDR_1 = 0x21,
	RF230_PAN_ID_0 = 0x22,
	RF230_PAN_ID_1 = 0x23,
	RF230_IEEE_ADDR_0 = 0x24,
	RF230_IEEE_ADDR_1 = 0x25,
	RF230_IEEE_ADDR_2 = 0x26,
	RF230_IEEE_ADDR_3 = 0x27,
	RF230_IEEE_ADDR_4 = 0x28,
	RF230_IEEE_ADDR_5 = 0x29,
	RF230_IEEE_ADDR_6 = 0x2A,
	RF230_IEEE_ADDR_7 = 0x2B,
	RF230_XAH_CTRL = 0x2C,
	RF230_CSMA_SEED_0 = 0x2D,
	RF230_CSMA_SEED_1 = 0x2E,
};

enum rf230_trx_register_enums
{
	RF230_CCA_DONE = 1 << 7,
	RF230_CCA_STATUS = 1 << 6,
	RF230_TRX_STATUS_MASK = 0x1F,
	RF230_P_ON = 0,
	RF230_BUSY_RX = 1,
	RF230_BUSY_TX = 2,
	RF230_RX_ON = 6,
	RF230_TRX_OFF = 8,
	RF230_PLL_ON = 9,
	RF230_SLEEP = 15,
	RF230_BUSY_RX_AACK = 17,
	RF230_BUSR_TX_ARET = 18,
	RF230_RX_AACK_ON = 22,
	RF230_TX_ARET_ON = 25,
	RF230_RX_ON_NOCLK = 28,
	RF230_AACK_ON_NOCLK = 29,
	RF230_BUSY_RX_AACK_NOCLK = 30,
	RF230_STATE_TRANSITION_IN_PROGRESS = 31,
	RF230_TRAC_STATUS_MASK = 0xE0,
	RF230_TRAC_SUCCESS = 0,
	RF230_TRAC_SUCCESS_DATA_PENDING = 1 << 5,
	RF230_TRAC_CHANNEL_ACCESS_FAILURE = 3 << 5,
	RF230_TRAC_NO_ACK = 5 << 5,
	RF230_TRAC_INVALID = 7 << 5,
	RF230_TRX_CMD_MASK = 0x1F,
	RF230_NOP = 0,
	RF230_TX_START = 2,
	RF230_FORCE_TRX_OFF = 3,
};

enum rf230_phy_register_enums
{
	RF230_TX_AUTO_CRC_ON = 1 << 7,
	RF230_TX_PWR_MASK = 0x0F,
	RF230_RSSI_MASK = 0x1F,
	RF230_CCA_REQUEST = 1 << 7,
	RF230_CCA_MODE_0 = 0 << 5,
	RF230_CCA_MODE_1 = 1 << 5,
	RF230_CCA_MODE_2 = 2 << 5,
	RF230_CCA_MODE_3 = 3 << 5,
	RF230_CHANNEL_MASK = 0x1F,
	RF230_CCA_CS_THRES_SHIFT = 4,
	RF230_CCA_ED_THRES_SHIFT = 0,
};

enum rf230_irq_register_enums
{
	RF230_IRQ_BAT_LOW = 1 << 7,
	RF230_IRQ_TRX_UR = 1 << 6,
	RF230_IRQ_TRX_END = 1 << 3,
	RF230_IRQ_RX_START = 1 << 2,
	RF230_IRQ_PLL_UNLOCK = 1 << 1,
	RF230_IRQ_PLL_LOCK = 1 << 0,
};

enum rf230_control_register_enums
{
	RF230_AVREG_EXT = 1 << 7,
	RF230_AVDD_OK = 1 << 6,
	RF230_DVREG_EXT = 1 << 3,
	RF230_DVDD_OK = 1 << 2,
	RF230_BATMON_OK = 1 << 5,
	RF230_BATMON_VHR = 1 << 4,
	RF230_BATMON_VTH_MASK = 0x0F,
	RF230_XTAL_MODE_OFF = 0 << 4,
	RF230_XTAL_MODE_EXTERNAL = 4 << 4,
	RF230_XTAL_MODE_INTERNAL = 15 << 4,
};

enum rf230_pll_register_enums
{
	RF230_PLL_CF_START = 1 << 7,
	RF230_PLL_DCU_START = 1 << 7,
};

enum rf230_spi_command_enums
{
	RF230_CMD_REGISTER_READ = 0x80,
	RF230_CMD_REGISTER_WRITE = 0xC0,
	RF230_CMD_REGISTER_MASK = 0x3F,
	RF230_CMD_FRAME_READ = 0x20,
	RF230_CMD_FRAME_WRITE = 0x60,
	RF230_CMD_SRAM_READ = 0x00,
	RF230_CMD_SRAM_WRITE = 0x40,
};

#endif//__RF230DRIVERLAYER_H__
