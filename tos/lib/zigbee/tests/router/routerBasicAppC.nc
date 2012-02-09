/*
 * @author Stefano Tennina <sota@isep.ipp.pt>
 *
 */

#include <Timer.h>
#include "nwk_enumerations.h"

#if defined(PLATFORM_TELOSB)
	#include "UserButton.h"
#endif

#include "nwk_const_router.h"

configuration routerBasicAppC {
}
implementation
{
	components MainC;
	components LedsC;

	components routerBasicC as App;
	App.Boot -> MainC;
	App.Leds -> LedsC;

	components new TimerMilliC() as T_init;
	App.T_init -> T_init;

	components new TimerMilliC() as T_schedule;
	App.T_schedule -> T_schedule;

	components new TimerMilliC() as NetAssociationDeferredTimer;
	App.NetAssociationDeferredTimer -> NetAssociationDeferredTimer;

#if defined(PLATFORM_TELOSB)
	//User Button
	components UserButtonC;
	App.Get -> UserButtonC;
	App.Notify -> UserButtonC;
#endif

	components NWKC;
	App.NLDE_DATA ->NWKC.NLDE_DATA;
	App.NLME_NETWORK_DISCOVERY -> NWKC.NLME_NETWORK_DISCOVERY;
	App.NLME_START_ROUTER -> NWKC.NLME_START_ROUTER;
	App.NLME_JOIN -> NWKC.NLME_JOIN;
	App.NLME_LEAVE -> NWKC.NLME_LEAVE;
	App.NLME_RESET -> NWKC.NLME_RESET;
	App.NLME_SYNC -> NWKC.NLME_SYNC;
	App.NLME_GET -> NWKC.NLME_GET;
	App.NLME_SET -> NWKC.NLME_SET;
}

