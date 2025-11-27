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
 * @author David Moss
 * @version $Revision: 1.12 $ $Date: 2008/06/23 23:40:21 $
 */

#ifndef __CC2520_H__
#define __CC2520_H__




typedef uint8_t cc2520_status_t;

#ifndef TFRAMES_ENABLED
#define CC2520_IFRAME_TYPE
#endif

#ifndef PRINTF_ENABLED
#define PRINTF_ENABLED	0
#endif


/*
 *Security Header:
 * ---------------------------------------------------------
 * |Bytes:1		|	4	| 0/1/5/9	   |
 * |-------------------------------------------------------|
 * |Security Control 	| Frame Counter | Key Identifier   |
 * --------------------------------------------------------
 * Security Control : Specifies the Security Level(bit 0-2) and key identifier mode(bit 3-4)
 * Frame Counter : It is used to ensure the freshness(uniqueness) of each frame.Used
 * to provide protection from Replay Attack
 *
 */

/*
 *Security Levels
 *----------------------------------------------------------------------
 *|Security Level	| Security Suite Name	| Description	     	|
 *----------------------------------------------------------------------
 *|0			| None			| No security	        |
 *----------------------------------------------------------------------
 *|1			| MIC-32		| 32 Bit Authentication |
 *----------------------------------------------------------------------
 *|2			| MIC-64		| 64 Bit Authentication |
 *----------------------------------------------------------------------
 *|3			| MIC-128		| 128 Bit Authentication|
 *----------------------------------------------------------------------
 *|4			| ENC			| Encryption		|
 *----------------------------------------------------------------------
 *|5			| ENC-MIC-32		| Encryption and 32bit	|
 *|			|			| Authentication	|
 *----------------------------------------------------------------------
 *|6			| ENC-MIC-64		| Encryption and 64bit	|
 *|			|			| Authentication	|
 *----------------------------------------------------------------------
 *|7			| ENC-MIC-128		| Encryption and 128bit |
 *|			|			| Authentication	|
 *----------------------------------------------------------------------
 */

/*Key Identifier Modes
 * ---------------------------------------------------------------------
 *|Key Identifer Mode|	Description	 				|
 *----------------------------------------------------------------------
 *|00		     | Key is determined implicitly from the originator |
 *|		     | and recipient(s) of the frame,as indicated in the|
 *|		     | frame header					|
 *----------------------------------------------------------------------
 *|01		     |	Key is determined from the 1-octet key Index	|
 *|		     |  subfield of the keyidentifier field of the 	|
 *|		     |  auxiliary security header in conjunction with	|
 *|		     |  macDefaultKeySource				|
 *----------------------------------------------------------------------
 *|10		     |	Key is determined from the 4-octet key source	|
 *|		     |  subfield and the 1-octet key index subfield of	|
 *|		     |  of the keyidentifier field			|
 *----------------------------------------------------------------------
 *|11		     |	Key is determined from the 8-octet key source	|
 *|		     |	subfield and the 1-octet key index subfield of  |
 *|		     |  of the keyidentifier field			|
 *----------------------------------------------------------------------
 */

/*
 *Key Identifier Field:
 * The key Identifier field has a variable length and identifies the key that is used
 * for cryptographic protection of outgoing frames,either explicitly or in conjunction
 * with implicitly defined side information.The key identifier field shall be present
 * only if the key identifier mode subfield of the security control field of the
 * auxiliary security header is set to a value different than 0x00.
 *	-------------------------
 *	|Octets:0/4/8|1		|
 *	-------------------------
 *	|Key Source  |Key Index |
 *	-------------------------
 *
 *	Key Source : Indicates the originator of a group key
 *	Key Index  : Allows unique identification of different keys with the same
 *			originator.
 *
 */
 

typedef nx_struct security_header_t {
  nx_uint8_t secLevel:3;
  nx_uint8_t keyMode:2;	//This will fix it to 0x00
  nx_uint8_t reserved:3;
  nx_uint32_t frameCounter;
} security_header_t;


/**
 * CC2520 header.  An I-frame (interoperability frame) header has an 
 * extra network byte specified by 6LowPAN
 */
typedef nx_struct cc2520_header_t {
  nxle_uint8_t length;
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  nxle_uint16_t destpan;
  nxle_uint16_t dest;
  nxle_uint16_t src;
    /** CC2420 802.15.4 header ends here */
#ifdef CC2520_HW_SECURITY
  security_header_t secHdr;
#endif
  /** I-Frame 6LowPAN interoperability byte */
#ifdef CC2520_IFRAME_TYPE
  nxle_uint8_t network;
#endif
  nxle_uint8_t type;

} cc2520_header_t;
  
/**
 * CC2420 Packet Footer
 */
typedef nx_struct cc2520_footer_t {
} cc2520_footer_t;

/**
 * CC2520 Packet metadata. Contains extra information about the message
 * that will not be transmitted.
 *
 * Note that the first two bytes automatically take in the values of the
 * FCS when the payload is full. Do not modify the first two bytes of metadata.
 */
typedef nx_struct cc2520_metadata_t {
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t tx_power;
  nx_bool crc;
  nx_bool ack;
  nx_bool timesync;
  nx_uint32_t timestamp;
  nx_uint16_t rxInterval;

  /** Packet Link Metadata */
//#ifdef PACKET_LINK
  nx_uint16_t maxRetries;
  nx_uint16_t retryDelay;
//#endif

} cc2520_metadata_t;


typedef nx_struct cc2520_packet_t {
  cc2520_header_t packet;
  nx_uint8_t data[];
} cc2520_packet_t;


#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 28//28
#endif

#ifndef CC2520_DEF_CHANNEL
#define CC2520_DEF_CHANNEL 26
#endif

#ifndef CC2520_DEF_RFPOWER
#define CC2520_DEF_RFPOWER 31
#endif




/**
 * Ideally, your receive history size should be equal to the number of
 * RF neighbors your node will have
 */
#ifndef RECEIVE_HISTORY_SIZE
#define RECEIVE_HISTORY_SIZE 4
#endif

/** 
 * The 6LowPAN NALP ID for a TinyOS network is 63 (TEP 125).
 */
#ifndef TINYOS_6LOWPAN_NETWORK_ID
#define TINYOS_6LOWPAN_NETWORK_ID 0x3f
#endif


enum {
  // size of the header not including the length byte
  MAC_HEADER_SIZE = sizeof( cc2520_header_t ) - 1,
  // size of the footer (FCS field)
  MAC_FOOTER_SIZE = sizeof( uint16_t ),
  // MDU
  MAC_PACKET_SIZE = MAC_HEADER_SIZE + TOSH_DATA_LENGTH + MAC_FOOTER_SIZE,

  CC2520_SIZE = MAC_HEADER_SIZE + MAC_FOOTER_SIZE,
};

enum cc2520_enums {
  CC2520_TIME_ACK_TURNAROUND = 7, // jiffies
  CC2520_TIME_VREN = 200,          // jiffies CC2520_VREG_MAX_STARTUP_TIME  -- lijo
  CC2520_TIME_SYMBOL = 16,//2,         // 2 symbols / jiffy
  CC2520_BACKOFF_PERIOD = ( 20 / CC2520_TIME_SYMBOL ), // symbols
  CC2520_MIN_BACKOFF = ( 20 / CC2520_TIME_SYMBOL ),  // platform specific?
  CC2520_ACK_WAIT_DELAY = 256,    // jiffies
};

enum cc2420_status_enums {
 /* CC2420_STATUS_RSSI_VALID = 1 << 1,
  CC2420_STATUS_LOCK = 1 << 2,
  CC2420_STATUS_TX_ACTIVE = 1 << 3,
  CC2420_STATUS_ENC_BUSY = 1 << 4,
  CC2420_STATUS_TX_UNDERFLOW = 1 << 5,
  CC2420_STATUS_XOSC16M_STABLE = 1 << 6,*/

  // modified by lijo on 03/12/2009

	CC2520_STATUS_RX_ACTIVE		= 1 << 0,
	CC2520_STATUS_TX_ACTIVE 	= 1 << 1,
	CC2520_STATUS_DPUL_ACTIVE 	= 1 << 2,
	CC2520_STATUS_DPUH_ACTIVE 	= 1 << 3,
	CC2520_STATUS_EXCEP_CHANNEL_B 	= 1 << 4,
	CC2520_STATUS_EXCEP_CHANNEL_A 	= 1 << 5,
	CC2520_STATUS_RSSI_VALID 	= 1 << 6,
	CC2520_STATUS_XOSC16M_STABLE 	= 1 << 7,
};

/*
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
  CC2420_STXENC = 0x0d,
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
}; */

enum cc2520_config_reg_enums {

    // FREG Registers

    CC2520_FRMFILT0 	= 0x00,
    CC2520_FRMFILT1 	= 0x01,
    CC2520_SRCMATCH 	= 0x02,
    CC2520_SRCSHORTEN0 	= 0x04,
    CC2520_SRCSHORTEN1 	= 0x05,
    CC2520_SRCSHORTEN2  = 0x06,
    CC2520_SRCEXTEN0 	= 0x08,
    CC2520_SRCEXTEN1 	= 0x09,
    CC2520_SRCEXTEN2 	= 0x0A,
    CC2520_FRMCTRL0 	= 0x0C,
    CC2520_FRMCTRL1 	= 0x0D,
    CC2520_RXENABLE0 	= 0x0E,
    CC2520_RXENABLE1 	= 0x0F,
    CC2520_EXCFLAG0 	= 0x10,
    CC2520_EXCFLAG1 	= 0x11,
    CC2520_EXCFLAG2 	= 0x12,
    CC2520_EXCMASKA0 	= 0x14,
    CC2520_EXCMASKA1 	= 0x15,
    CC2520_EXCMASKA2 	= 0x16,
    CC2520_EXCMASKB0 	= 0x18,
    CC2520_EXCMASKB1 	= 0x19,
    CC2520_EXCMASKB2 	= 0x1A,
    CC2520_EXCBINDX0 	= 0x1C,
    CC2520_EXCBINDX1 	= 0x1D,
    CC2520_EXCBINDY0 	= 0x1E,
    CC2520_EXCBINDY1 	= 0x1F,
    CC2520_GPIOCTRL0 	= 0x20,
    CC2520_GPIOCTRL1 	= 0x21,
    CC2520_GPIOCTRL2 	= 0x22,
    CC2520_GPIOCTRL3 	= 0x23,
    CC2520_GPIOCTRL4 	= 0x24,
    CC2520_GPIOCTRL5 	= 0x25,
    CC2520_GPIOPOLARITY = 0x26,
    CC2520_GPIOCTRL 	= 0x28,
    CC2520_DPUCON 	= 0x2A,
    CC2520_DPUSTAT 	= 0x2C,
    CC2520_FREQCTRL 	= 0x2E,
    CC2520_FREQTUNE 	= 0x2F,
    CC2520_TXPOWER 	= 0x30,
    CC2520_TXCTRL 	= 0x31,
    CC2520_FSMSTAT0 	= 0x32,
    CC2520_FSMSTAT1 	= 0x33,
    CC2520_FIFOPCTRL 	= 0x34,
    CC2520_FSMCTRL 	= 0x35,
    CC2520_CCACTRL0 	= 0x36,
    CC2520_CCACTRL1 	= 0x37,
    CC2520_RSSI 	= 0x38,
    CC2520_RSSISTAT 	= 0x39,
    CC2520_RXFIRST 	= 0x3C,
    CC2520_RXFIFOCNT 	= 0x3E,
    CC2520_TXFIFOCNT 	= 0x3F,

    // SREG registers
    CC2520_CHIPID 	= 0x40,
    CC2520_VERSION 	= 0x42,
    CC2520_EXTCLOCK 	= 0x44,
    CC2520_MDMCTRL0 	= 0x46,
    CC2520_MDMCTRL1 	= 0x47,
    CC2520_FREQEST 	= 0x48,
    CC2520_RXCTRL 	= 0x4A,
    CC2520_FSCTRL 	= 0x4C,
    CC2520_FSCAL0 	= 0x4E,
    CC2520_FSCAL1 	= 0x4F,
    CC2520_FSCAL2 	= 0x50,
    CC2520_FSCAL3 	= 0x51,
    CC2520_AGCCTRL0 	= 0x52,
    CC2520_AGCCTRL1 	= 0x53,
    CC2520_AGCCTRL2 	= 0x54,
    CC2520_AGCCTRL3 	= 0x55,
    CC2520_ADCTEST0 	= 0x56,
    CC2520_ADCTEST1 	= 0x57,
    CC2520_ADCTEST2 	= 0x58,
    CC2520_MDMTEST0 	= 0x5A,
    CC2520_MDMTEST1 	= 0x5B,
    CC2520_DACTEST0 	= 0x5C,
    CC2520_DACTEST1 	= 0x5D,
    CC2520_ATEST 	= 0x5E,
    CC2520_DACTEST2 	= 0x5F,
    CC2520_PTEST0 	= 0x60,
    CC2520_PTEST1 	= 0x61,
    CC2520_RESERVED 	= 0x62,
    CC2520_DPUBIST 	= 0x7A,
    CC2520_ACTBIST 	= 0x7C,
    CC2520_RAMBIST 	= 0x7E,

};

enum cc2520_spi_command_enums
{
    CC2520_CMD_SNOP 		= 0x00, //
    CC2520_CMD_IBUFLD 		= 0x02, //
    CC2520_CMD_SIBUFEX 		= 0x03, //
    CC2520_CMD_SSAMPLECCA 	= 0x04, //
    CC2520_CMD_SRES 		= 0x0f, //
    CC2520_CMD_MEMORY_MASK 	= 0x0f, //
    CC2520_CMD_MEMORY_READ 	= 0x10, // MEMRD
    CC2520_CMD_MEMORY_WRITE 	= 0x20, // MEMWR
    CC2520_CMD_RXBUF 		= 0x30, //
    CC2520_CMD_RXBUFCP 		= 0x38, //
    CC2520_CMD_RXBUFMOV 	= 0x32, //
    CC2520_CMD_TXBUF 		= 0x3A, //
    CC2520_CMD_TXBUFCP 		= 0x3E, //
    CC2520_CMD_RANDOM 		= 0x3C, //
    CC2520_CMD_SXOSCON 		= 0x40, //
    CC2520_CMD_STXCAL 		= 0x41, //
    CC2520_CMD_SRXON 		= 0x42, //
    CC2520_CMD_STXON 		= 0x43, //
    CC2520_CMD_STXONCCA 	= 0x44, //
    CC2520_CMD_SRFOFF 		= 0x45, //
    CC2520_CMD_SXOSCOFF 	= 0x46, //
    CC2520_CMD_SFLUSHRX 	= 0x47, //
    CC2520_CMD_SFLUSHTX 	= 0x48, //
    CC2520_CMD_SACK 		= 0x49, //
    CC2520_CMD_SACKPEND 	= 0x4A, //
    CC2520_CMD_SNACK 		= 0x4B, //
    CC2520_CMD_SRXMASKBITSET 	= 0x4C, //
    CC2520_CMD_SRXMASKBITCLR 	= 0x4D, //
    CC2520_CMD_RXMASKAND 	= 0x4E, //
    CC2520_CMD_RXMASKOR 	= 0x4F, //
    CC2520_CMD_MEMCP 		= 0x50, //
    CC2520_CMD_MEMCPR 		= 0x52, //
    CC2520_CMD_MEMXCP 		= 0x54, //
    CC2520_CMD_MEMXWR 		= 0x56, //
    CC2520_CMD_BCLR 		= 0x58, //
    CC2520_CMD_BSET 		= 0x59, //
    CC2520_CMD_CTR_UCTR 	= 0x60, //
    CC2520_CMD_CBCMAC 		= 0x64, //
    CC2520_CMD_UCBCMAC 		= 0x66, //
    CC2520_CMD_CCM 		= 0x68, //
    CC2520_CMD_UCCM 		= 0x6A, //
    CC2520_CMD_ECB 		= 0x70, //
    CC2520_CMD_ECBO 		= 0x72, //
    CC2520_CMD_ECBX 		= 0x74, //
    CC2520_CMD_INC 		= 0x78, //
    CC2520_CMD_ABORT 		= 0x7F, //
    CC2520_CMD_REGISTER_READ 	= 0x80, //
    CC2520_CMD_REGISTER_WRITE 	= 0xC0, //
};

enum cc2520_security_enums{
  CC2520_NO_SEC = 0,
  CC2520_CBC_MAC = 1,
  CC2520_CTR = 2,
  CC2520_CCM = 3,
  NO_SEC = 0,
  CBC_MAC_4 = 1,
  CBC_MAC_8 = 2,
  CBC_MAC_16 = 3,
  CTR = 4,
  CCM_4 = 5,
  CCM_8 = 6,
  CCM_16 = 7
};


//Different Security Levels
	
enum security_levels {
	SEC_NONE		=	0x00,
	SEC_MIC_32		=	0x01,
	SEC_MIC_64		=	0x02,
	SEC_MIC_128		=	0x03,
	SEC_ENC			=	0x04,
	SEC_ENC_MIC_32		=	0x05,
	SEC_ENC_MIC_64		=	0x06,
	SEC_ENC_MIC_128		=	0x07,		
};

//Different Flags 
enum initialization_flags{
	FLAG_NONE			=	0x00,
	FLAG_MIC_32			=	0x09,
	FLAG_MIC_64			= 	0x19,
	FLAG_MIC_128			=	0x39,
	FLAG_ENC			= 	0x01,
	FLAG_ENC_MIC_32			=	0x09,
	FLAG_ENC_MIC_64			= 	0x19,
	FLAG_ENC_MIC_128		=	0x39,		
};

/*
enum cc2520_exception_enums {

 CC2520_EXC_RF_IDLE          =   0x00,
 CC2520_EXC_TX_FRM_DONE      =   0x01,
 CC2520_EXC_TX_ACK_DONE      =   0x02,
 CC2520_EXC_TX_UNDERFLOW     =   0x03,
 CC2520_EXC_TX_OVERFLOW      =   0x04,
 CC2520_EXC_RX_UNDERFLOW     =   0x05,
 CC2520_EXC_RX_OVERFLOW      =   0x06,
 CC2520_EXC_RXENABLE_ZERO    =   0x07,
 CC2520_EXC_RX_FRM_DONE      =   0x08,
 CC2520_EXC_RX_FRM_ACCEPTED  =   0x09,
 CC2520_EXC_SRC_MATCH_DONE   =   0x0A,
 CC2520_EXC_SRC_MATCH_FOUND  =   0x0B,
 CC2520_EXC_FIFOP            =   0x0C,
 CC2520_EXC_SFD              =   0x0D,
 CC2520_EXC_DPU_DONE_L       =   0x0E,
 CC2520_EXC_DPU_DONE_H       =   0x0F,
 CC2520_EXC_MEMADDR_ERROR    =   0x10,
 CC2520_EXC_USAGE_ERROR      =   0x11,
 CC2520_EXC_OPERAND_ERROR    =   0x12,
 CC2520_EXC_SPI_ERROR        =   0x13,
 CC2520_EXC_RF_NO_LOCK       =   0x14,
 CC2520_EXC_RX_FRM_ABORTED   =   0x15,
 CC2520_EXC_RXBUFMOV_TIMEOUT =   0x16,
};*/

enum cc2520_exception_enums {

 CC2520_EXC_RF_IDLE          =   0x01,
 CC2520_EXC_TX_FRM_DONE      =   0x02,
 CC2520_EXC_TX_ACK_DONE      =   0x03,
 CC2520_EXC_TX_UNDERFLOW     =   0x04,
 CC2520_EXC_TX_OVERFLOW      =   0x05,
 CC2520_EXC_RX_UNDERFLOW     =   0x06,
 CC2520_EXC_RX_OVERFLOW      =   0x07,
 CC2520_EXC_RXENABLE_ZERO    =   0x08,
 CC2520_EXC_RX_FRM_DONE      =   0x09,
 CC2520_EXC_RX_FRM_ACCEPTED  =   0x0A,
 CC2520_EXC_SRC_MATCH_DONE   =   0x0B,
 CC2520_EXC_SRC_MATCH_FOUND  =   0x0C,
 CC2520_EXC_FIFOP            =   0x0D,
 CC2520_EXC_SFD              =   0x0E,
 CC2520_EXC_DPU_DONE_L       =   0x0F,
 CC2520_EXC_DPU_DONE_H       =   0x10,
 CC2520_EXC_MEMADDR_ERROR    =   0x11,
 CC2520_EXC_USAGE_ERROR      =   0x12,
 CC2520_EXC_OPERAND_ERROR    =   0x13,
 CC2520_EXC_SPI_ERROR        =   0x14,
 CC2520_EXC_RF_NO_LOCK       =   0x15,
 CC2520_EXC_RX_FRM_ABORTED   =   0x16,
 CC2520_EXC_RXBUFMOV_TIMEOUT =   0x17,
};

enum cc2520_GPIO_output_enums {

	CC2520_GPIO_EXC_CH_A       =    0x21,
	CC2520_GPIO_EXC_CH_B       =    0x22,
	CC2520_GPIO_EXC_CH_INVA    =    0x23,
	CC2520_GPIO_EXC_CH_INVB    =    0x24,
	CC2520_GPIO_EXC_CH_RX      =    0x25,
	C2520_GPIO_EXC_CH_ERR      =    0x26,
	CC2520_GPIO_FIFO           =    0x27,
	CC2520_GPIO_FIFOP          =    0x28,
	CC2520_GPIO_CCA            =    0x29,
	CC2520_GPIO_SFD            =    0x2A,
	CC2520_GPIO_RSSI_VALID     =    0x2C,
	CC2520_GPIO_SAMPLED_CCA    =    0x2D,
	CC2520_GPIO_SNIFFER_CLK    =    0x31,
	CC2520_GPIO_SNIFFER_DATA   =    0x32,
	CC2520_GPIO_RX_ACTIVE      =    0x43,
	CC2520_GPIO_TX_ACTIVE      =    0x44,
	CC2520_GPIO_LOW            =    0x7E,
	CC2520_GPIO_HIGH           =    0x7F,
};

enum cc2520_reg_access_enums {
    CC2520_FREG_MASK = 0x3F, // highest address in FREG
    CC2520_SREG_MASK = 0x7F, // highest address in SREG
    //CC2520_CMD_REGISTER_WRITE = 0xC0,
};
/*
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
*/

enum cc2520_ram_addr_enums {

  CC2520_RAM_TXFIFO 	= 0x100,
  CC2520_RAM_RXFIFO 	= 0x180,
  CC2520_RAM_TXFRAME	= 0x200,	//Allocate 127 Bytes MTU to a Frame
  CC2520_RAM_RXFRAME 	= 0x280,
  CC2520_RAM_KEY0 	= 0x300,
  CC2520_RAM_TXNONCE 	= 0x310,
  CC2520_RAM_RXNONCE 	= 0x320,
  CC2520_RAM_SABUF 	= 0x220,
  CC2520_RAM_CBCSTATE 	= 0x360,


  
  CC2520_RAM_PANID 	= 0x3F2,
  CC2520_RAM_SHORTADR 	= 0x3F4,
  CC2520_RAM_IEEEADR 	= 0x3EA,
};

enum cc2520_nonce_enums {
  CC2520_NONCE_BLOCK_COUNTER = 0,
  CC2520_NONCE_KEY_SEQ_COUNTER = 2,
  CC2520_NONCE_FRAME_COUNTER = 3,
  CC2520_NONCE_SOURCE_ADDRESS = 7,
  CC2520_NONCE_FLAGS = 15,
};



enum cc2520_mdmctrl0_enums {
  
  CC2520_MDMCTRL0_DEM_NUM_ZEROS = 6,
  CC2520_MDMCTRL0_DEMOD_AVG_MODE = 5,
  CC2520_MDMCTRL0_PREAMBLE_LENGTH = 1,
  CC2520_MDMCTRL0_TX_FILTER = 0,
};

enum cc2520_mdmctrl1_enums {
 
  CC2520_MDMCTRL1_RESERVED = 6,
  CC2520_MDMCTRL1_CORR_THR_SFD = 5,
  CC2520_MDMCTRL1_CORR_THR = 0,
};


enum cc2520_frmctrl0_enums {

   CC2520_FMCTRL0_APPEND_DATA_MODE = 7, 
   CC2520_FMCTRL0_AUTOCRC     = 6, 
   CC2520_FMCTRL0_AUTOACK     = 5, 
   CC2520_FMCTRL0_ENERGY_SCAN = 4,
   CC2520_FMCTRL0_RX_MODE     = 2,
   CC2520_FMCTRL0_TX_MODE     = 0,
 
  
};

enum cc2520_freqctrl_enums {

   CC2520_FREQCTRL_RESERVED = 7, 
   CC2520_FREQCTRL_FREQ     = 0, 
};

enum cc2520_txpower_enums {
  CC2520_TXPOWER_PA_POWER = 0,
};

enum cc2520_frmfilt0_enums {

   CC2520_FRMFILT0_RESERVED          = 7, 
   CC2520_FRMFILT0_FCF_RESERVED_MASK = 4, 
   CC2520_FRMFILT0_MAX_FRAME_VERSION = 2, 
   CC2520_FRMFILT0_PAN_COORDINATOR   = 1,
   CC2520_FRMFILT0_FRAME_FILTER_EN   = 0,
    
};

enum cc2520_frmfilt1_enums {

   CC2520_FRMFILT1_ACCEPT_FT_4TO7      = 7, 
   CC2520_FRMFILT1_ACCEPT_FT_3_MAC_CMD = 6, 
   CC2520_FRMFILT1_ACCEPT_FT_2_ACK     = 5, 
   CC2520_FRMFILT1_ACCEPT_FT_1_DATA    = 4,
   CC2520_FRMFILT1_ACCEPT_FT_0_BEACON  = 3,
   C2520_FRMFILT1_MODIFY_FT_FILTER     = 1,
   C2520_FRMFILT1_RESERVED             = 0,
};

enum cc2520_srcmatch_enums {
  CC2520_SRCMATCH_RESERVED = 3,
  CC2520_SRCMATCH_PEND_DATAREQ_ONLY = 2,
  CC2520_SRCMATCH_AUTOPEND = 1,
  CC2520_SRCMATCH_ENABLE = 0,
};

enum cc2520_fifopctrl_enums {

   CC2520_FIFOPCTRL_RESERVED  = 7, 
   CC2520_FIFOPCTRL_FIFOP_THR = 0, 
};


enum cc2520_ccactrl0_enums {

   CC2520_CCACTRL0_CCA_THR  = 0, 
};

typedef union cc2520_rxctrl {
    uint8_t value;
} cc2520_rxctrl_t;
static cc2520_rxctrl_t cc2520_rxctrl_default = {.value = 0x32};

enum
{
  CC2520_INVALID_TIMESTAMP  = 0x80000000L,
};


/*
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

enum
{
  CC2420_INVALID_TIMESTAMP  = 0x80000000L,
};
*/
#endif
