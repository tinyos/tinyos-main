/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 */
 
#ifndef __PHY_ENUMERATIONS__
#define __PHY_ENUMERATIONS__
 
 
//phy status enumerations
enum{
	PHY_BUSY = 0x00,
	PHY_BUSY_RX = 0x01,
	PHY_BUSY_TX = 0x02,
	PHY_FORCE_TRX_OFF = 0x03,
	PHY_IDLE = 0x04,
	PHY_INVALID_PARAMETER = 0x05,
	PHY_RX_ON = 0x06,
	PHY_SUCCESS = 0x07,
	PHY_TRX_OFF = 0x08,
	PHY_TX_ON = 0x09,
	PHY_UNSUPPORTED_ATTRIBUTE = 0x0a
};

//phy PIB attributes enumerations
enum{
	PHYCURRENTCHANNEL = 0x00,
	PHYCHANNELSSUPPORTED = 0X01,
	PHYTRANSMITPOWER = 0X02,
	PHYCCAMODE=0X03
};

#endif
