/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include <Timer.h>

configuration MacC {


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
	MainC.SoftwareInit -> MacP;

	components LedsC;
	components MacP;

	components PhyC;

	components TimerAsyncC;
	
	MacP.TimerAsync ->TimerAsyncC;

	MacP.Leds -> LedsC;
	
	
	MacP.AMControl ->PhyC.SplitControl;
	
	components HplCC2420PinsC as Pins;
	MacP.CCA -> Pins.CCA;
	
	components RandomC;
	MacP.Random -> RandomC;

	components new TimerMilliC() as T_ackwait;
	MacP.T_ackwait -> T_ackwait;
	
	components new TimerMilliC() as T_ResponseWaitTime;
	MacP.T_ResponseWaitTime -> T_ResponseWaitTime;
	
	components new TimerMilliC() as T_ScanDuration;
	MacP.T_ScanDuration -> T_ScanDuration;

	components CC2420ReceiveC;
	MacP.AddressFilter -> CC2420ReceiveC;

	/*****************************************************/
	/*				INTERFACES         					 */
	/*****************************************************/  
	MacP.PD_DATA -> PhyC.PD_DATA;
	MacP.PLME_ED ->PhyC.PLME_ED;
	MacP.PLME_CCA -> PhyC.PLME_CCA;
	MacP.PLME_SET -> PhyC.PLME_SET;
	MacP.PLME_GET -> PhyC.PLME_GET;
	MacP.PLME_SET_TRX_STATE -> PhyC.PLME_SET_TRX_STATE;


	//MLME interfaces
	MLME_START=MacP;

	MLME_SET=MacP;
	MLME_GET=MacP;
	
	MLME_ASSOCIATE=MacP;
	MLME_DISASSOCIATE=MacP;
	
	MLME_BEACON_NOTIFY = MacP;
	MLME_GTS=MacP;
	
	MLME_ORPHAN=MacP;
	
	MLME_SYNC=MacP;
	MLME_SYNC_LOSS=MacP;
	
	MLME_RESET=MacP;
	
	MLME_SCAN=MacP;
	
	MCPS_DATA=MacP;
	MCPS_PURGE=MacP;
	
	
	
	

}

