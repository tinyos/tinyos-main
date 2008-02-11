enum {
	COORDINATOR = 0x00,
	ROUTER =0x01,
	END_DEVICE = 0x02
	};

#define BEACON_ORDER 6
#define SUPERFRAME_ORDER 4
//the starting channel needs to be diferrent that the existent coordinator operating channels
#define LOGICAL_CHANNEL 0x15
 

#define TYPE_DEVICE END_DEVICE
//#define TYPE_DEVICE COORDINATOR

//PAN VARIABLES
#define MAC_PANID 0x1234


