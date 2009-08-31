/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>

#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"

#include "nwk_const.h"
#include "nwk_enumerations.h"
#include "nwk_func.h"
#include "UserButton.h"

#include "Test_APL.h"


configuration Test_APL {
}
implementation {

  components MainC;
  components LedsC;
  components Test_APLM;
    
  Test_APLM.Boot -> MainC;
    
  components NWK;
  
  Test_APLM.Leds -> LedsC;
  
  
	components new TimerMilliC() as T_init;
	Test_APLM.T_init -> T_init;
		
	components new TimerMilliC() as T_test;
	Test_APLM.T_test -> T_test;
		
	components new TimerMilliC() as T_schedule;
	Test_APLM.T_schedule -> T_schedule;
  
  
  //User Button
  components UserButtonC;

  Test_APLM.Get -> UserButtonC;
  Test_APLM.Notify -> UserButtonC;
  
  
  Test_APLM.NLDE_DATA ->NWK.NLDE_DATA;
  
  Test_APLM.NLME_NETWORK_DISCOVERY -> NWK.NLME_NETWORK_DISCOVERY;
  Test_APLM.NLME_NETWORK_FORMATION -> NWK.NLME_NETWORK_FORMATION;
  /*Test_APLM.NLME_PERMIT_JOINING-> NWK_control.NLME_PERMIT_JOINING;
  */
  Test_APLM.NLME_START_ROUTER -> NWK.NLME_START_ROUTER;
  Test_APLM.NLME_JOIN -> NWK.NLME_JOIN;
  /*Test_APLM.NLME_DIRECT_JOIN -> NWK_control.NLME_DIRECT_JOIN;
  */
  Test_APLM.NLME_LEAVE -> NWK.NLME_LEAVE;
  /*Test_APLM.NLME_RESET -> NWK_control.NLME_RESET;
  */
  Test_APLM.NLME_SYNC -> NWK.NLME_SYNC;
  Test_APLM.NLME_GET -> NWK.NLME_GET;
  Test_APLM.NLME_SET -> NWK.NLME_SET;
}

