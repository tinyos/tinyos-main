/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 */


#ifndef __PHY_CONST__
#define __PHY_CONST__
 
// The PHY constants are defined here.
#define aMaxPHYPacketSize  127
#define aTurnaroundTime 12

#define INIT_CURRENTCHANNEL 0x15
#define INIT_CHANNELSSUPPORTED 0x0
#define INIT_TRANSMITPOWER 15
#define INIT_CCA_MODE 0

#define CCA_IDLE 0
#define CCA_BUSY 1

// PHY PIB attribute and psdu
typedef struct
{
	uint8_t phyCurrentChannel;
	uint8_t phyChannelsSupported;
	uint8_t phyTransmitPower;
	uint8_t phyCcaMode;
} phyPIB;

#endif

