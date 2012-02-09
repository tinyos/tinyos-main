/*
 * @author open-zb http://www.open-zb.net
 * @author Stefano Tennina
 */

//Choose which printfs to enable

#ifndef __LOG_ENABLE_H__
#define __LOG_ENABLE_H__

// XLayer Log Level Settings (enabled only if the LAYERS prints are enabled)
#define ERROR_CONDITIONS	0x01
#define DEBUG_STATUS		0x02
#define TRACE_FUNC			0x04
#define DBG_NEIGHBOR_TABLE	0x08
#define DBG_CUSTOM			0x10
#define TIME_PERFORMANCE	0x20

//#define LOG_LEVEL			(TIME_PERFORMANCE)
//#define LOG_LEVEL			(ERROR_CONDITIONS | DEBUG_STATUS | TRACE_FUNC)
//#define LOG_LEVEL			(ERROR_CONDITIONS)
#define LOG_LEVEL			(0)

// Local ENABLERS

// **********************************************
// ************** APPLICATION *******************
// **********************************************
// Uncomment this to globally enable printfs in APP
//#define APP_PRINTFS_ENABLED

// ******************************************
// ************** NETWORK *******************
// ******************************************
// Uncomment this to globally enable printfs in NWKP.nc
//#define NWK_PRINTFS_ENABLED

// Uncomment this to avoid IEEE154 status parsing messages
//#define DEBUG_STATUS_MESSAGE

// Uncomment this to enable prints of neighbor table
//#define DBG_LIST_NEIGHBOURS

#endif
