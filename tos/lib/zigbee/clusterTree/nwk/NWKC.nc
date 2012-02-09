/*
 * @author open-zb http://www.open-zb.net
 * @author Stefano Tennina
 */


#include <Timer.h>

#include "nwk_func.h"
#include "nwk_enumerations.h"

#ifdef IM_COORDINATOR
	#include "nwk_const_coordinator.h"
#else
	#ifdef IM_ROUTER
		#include "nwk_const_router.h"
	#else
		#include "nwk_const_end_device.h"
	#endif
#endif


configuration NWKC {
	
	provides
	{ 
		//NLDE NWK data service
		interface NLDE_DATA;
	

		//NLME NWK Management service
#ifdef IM_COORDINATOR
		interface NLME_NETWORK_FORMATION;
#else
		interface NLME_NETWORK_DISCOVERY;
#endif

#ifdef IM_ROUTER
		interface NLME_START_ROUTER;
#endif

		interface NLME_SYNC;		// It implements both request and indication!
		interface NLME_JOIN;		// It implements both request and indication!
		interface NLME_LEAVE;
	
		interface NLME_RESET;
	
		interface NLME_GET;
		interface NLME_SET;
	}

}
implementation {

	// Coordinator
	components MainC, LedsC, Ieee802154BeaconEnabledC as MAC;
	components NWKP;
	MainC.SoftwareInit -> NWKP;
#ifdef IM_ROUTER
	components new PoolC(message_t, ROUTER_FRAME_POOL_SIZE) as FramePool;
	NWKP.FramePool -> FramePool;
#endif

	NWKP.Leds -> LedsC;
	//components RandomC;
	//NWKP.Random -> RandomC;
	components RandomLfsrC;
	NWKP.Random -> RandomLfsrC;

	// Interface with MAC
	NWKP.MLME_RESET -> MAC;
	NWKP.MLME_START -> MAC;
	NWKP.MCPS_DATA -> MAC;
	NWKP.MLME_SET -> MAC;
	NWKP.MLME_GET -> MAC;

	NWKP.MLME_ASSOCIATE -> MAC;
	NWKP.MLME_COMM_STATUS -> MAC;

	NWKP.MLME_SYNC -> MAC;
	NWKP.MLME_SYNC_LOSS -> MAC;
	
	
	
#ifndef IM_COORDINATOR
	NWKP.MLME_SCAN -> MAC;
	NWKP.MLME_BEACON_NOTIFY -> MAC;
	NWKP.MLME_DISASSOCIATE -> MAC;
#endif

	// Packet's Types
#ifndef IM_END_DEVICE
	NWKP.IEEE154TxBeaconPayload -> MAC;
#endif
	NWKP.Frame -> MAC;
	NWKP.Packet -> MAC;
#ifndef IM_COORDINATOR
	NWKP.BeaconFrame -> MAC;
#endif

	//MAC interfaces Still excluded
	//NWKP.MLME_GTS -> MacC.MLME_GTS;
	//NWKP.MLME_ORPHAN->MacC.MLME_ORPHAN;

	// NLDE NWK data service
	NLDE_DATA=NWKP;
	
	//NLME NWK Management service
#ifdef IM_COORDINATOR
	NLME_NETWORK_FORMATION=NWKP;
#else
	NLME_NETWORK_DISCOVERY=NWKP;
#endif
	
	NLME_JOIN=NWKP;
	
#ifdef IM_ROUTER
	NLME_START_ROUTER=NWKP;
#endif
	
	NLME_LEAVE=NWKP;
	
	NLME_RESET=NWKP;
	
	NLME_SYNC=NWKP;
	NLME_GET=NWKP;
	NLME_SET=NWKP;
	
#if (LOG_LEVEL & TIME_PERFORMANCE)
//	components LocalTimeMilliC;
//	NWKP.LocalTime -> LocalTimeMilliC;
	components LocalTimeMicroC;
	NWKP.LocalTime -> LocalTimeMicroC;
#endif
}
