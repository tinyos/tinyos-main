/*
 * @author open-zb http://www.open-zb.net
 * @author Stefano Tennina
 */

#ifndef __MAC_PROFILE__
#define __MAC_PROFILE__

// Default PAN ID
#ifndef DEF_MAC_PANID
#define MAC_PANID			0x123F
#else
#define MAC_PANID			DEF_MAC_PANID
#endif

// Default Channel
#ifndef DEF_CHANNEL
#define LOGICAL_CHANNEL 	26
#else
#define LOGICAL_CHANNEL 	DEF_CHANNEL
#endif

#define BEACON_ORDER		8
#define SUPERFRAME_ORDER	4

#define AVAILABLEADDRESSES 0x06
#define ADDRESSINCREMENT 0x0001
#define MAXCHILDREN		0x06
#define MAXDEPTH		0x03
#define MAXROUTERS		0x04

#endif
