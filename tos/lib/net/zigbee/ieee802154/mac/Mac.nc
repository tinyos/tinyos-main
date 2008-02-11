/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include <Timer.h>

configuration Mac {


		//MLME  
		provides interface MLME_START;
		provides interface MLME_SET;
		provides interface MLME_GET;
		
		provides interface MLME_ASSOCIATE;
		provides interface MLME_DISASSOCIATE;
		
		provides interface MLME_BEACON_NOTIFY;
		provides interface MLME_GTS;
		
		provides interface MLME_ORPHAN;

		provides interface MLME_SYNC;
		provides interface MLME_SYNC_LOSS;
		
		provides interface MLME_RESET;
		
		provides interface MLME_SCAN;
		
		//MCPS
		provides interface MCPS_DATA;
		provides interface MCPS_PURGE;

}
implementation {

	components MainC;
	MainC.SoftwareInit -> MacM;

	components LedsC;
	components MacM;

	components Phy;

	components TimerAsyncC;
	
	MacM.TimerAsync ->TimerAsyncC;

	MacM.Leds -> LedsC;
	
	
	MacM.AMControl ->Phy.SplitControl;
	
	components HplCC2420PinsC as Pins;
	MacM.CCA -> Pins.CCA;
	
	components RandomC;
	MacM.Random -> RandomC;

	components new TimerMilliC() as T_ackwait;
	MacM.T_ackwait -> T_ackwait;
	
	components new TimerMilliC() as T_ResponseWaitTime;
	MacM.T_ResponseWaitTime -> T_ResponseWaitTime;
	
	components new TimerMilliC() as T_ScanDuration;
	MacM.T_ScanDuration -> T_ScanDuration;

	components CC2420ReceiveC;
	MacM.AddressFilter -> CC2420ReceiveC;

	/*****************************************************/
	/*				INTERFACES         					 */
	/*****************************************************/  
	MacM.PD_DATA -> Phy.PD_DATA;
	MacM.PLME_ED ->Phy.PLME_ED;
	MacM.PLME_CCA -> Phy.PLME_CCA;
	MacM.PLME_SET -> Phy.PLME_SET;
	MacM.PLME_GET -> Phy.PLME_GET;
	MacM.PLME_SET_TRX_STATE -> Phy.PLME_SET_TRX_STATE;


	//MLME interfaces
	MLME_START=MacM;

	MLME_SET=MacM;
	MLME_GET=MacM;
	
	MLME_ASSOCIATE=MacM;
	MLME_DISASSOCIATE=MacM;
	
	MLME_BEACON_NOTIFY = MacM;
	MLME_GTS=MacM;
	
	MLME_ORPHAN=MacM;
	
	MLME_SYNC=MacM;
	MLME_SYNC_LOSS=MacM;
	
	MLME_RESET=MacM;
	
	MLME_SCAN=MacM;
	
	MCPS_DATA=MacM;
	MCPS_PURGE=MacM;
	
	
	
	

}

