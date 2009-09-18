/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */
#include <Timer.h>

#ifndef TKN154_MAC

#include "phy_const.h"
#include "phy_enumerations.h"
#include "mac_const.h"
#include "mac_enumerations.h"
#include "mac_func.h"

#endif

#include "nwk_const.h"
#include "nwk_enumerations.h"
#include "nwk_func.h"
#include "UserButton.h"



configuration Test_APLC {
}
implementation {

  components MainC;
  components LedsC;
  components Test_APLP;
    
  Test_APLP.Boot -> MainC;
    
  components NWKC;
  
  Test_APLP.Leds -> LedsC;
  
  
	components new TimerMilliC() as T_init;
	Test_APLP.T_init -> T_init;
		
	components new TimerMilliC() as T_test;
	Test_APLP.T_test -> T_test;
		
	components new TimerMilliC() as T_schedule;
	Test_APLP.T_schedule -> T_schedule;
  
  
  //User Button
  components UserButtonC;

  Test_APLP.Get -> UserButtonC;
  Test_APLP.Notify -> UserButtonC;
  
  
  Test_APLP.NLDE_DATA ->NWKC.NLDE_DATA;
  
  Test_APLP.NLME_NETWORK_DISCOVERY -> NWKC.NLME_NETWORK_DISCOVERY;
  Test_APLP.NLME_NETWORK_FORMATION -> NWKC.NLME_NETWORK_FORMATION;
  /*Test_APLP.NLME_PERMIT_JOINING-> NWKC.NLME_PERMIT_JOINING;
  */
  Test_APLP.NLME_START_ROUTER -> NWKC.NLME_START_ROUTER;
  Test_APLP.NLME_JOIN -> NWKC.NLME_JOIN;
  /*Test_APLP.NLME_DIRECT_JOIN -> NWKC.NLME_DIRECT_JOIN;
  */
  Test_APLP.NLME_LEAVE -> NWKC.NLME_LEAVE;
  Test_APLP.NLME_RESET -> NWKC.NLME_RESET;
  
  Test_APLP.NLME_SYNC -> NWKC.NLME_SYNC;
  Test_APLP.NLME_GET -> NWKC.NLME_GET;
  Test_APLP.NLME_SET -> NWKC.NLME_SET;
}

