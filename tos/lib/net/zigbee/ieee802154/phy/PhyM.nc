/*
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

#include "frame_format.h"

#include "phy_const.h"
#include "phy_enumerations.h"
 

module PhyM {

	provides interface SplitControl;
	// provides interface Test_send;
	
	
	//ieee802.15.4 phy interfaces
	provides interface PD_DATA;
	
	provides interface PLME_ED;
	provides interface PLME_CCA;
	provides interface PLME_SET;
	provides interface PLME_GET;
	provides interface PLME_SET_TRX_STATE;
	
	
	provides interface Init;
	
	uses interface Resource;
	uses interface CC2420Power;
	uses interface CC2420Config;
	uses interface StdControl as SubControl;
	
	uses interface Random;
	uses interface Leds;
	
	uses interface Sendframe;
	
	uses interface Receiveframe;

}

implementation {


	phyPIB phy_PIB;
	
	//transceiver current status
	//it can only be PHY_TRX_OFF, PHY_RX_ON and PHY_TX_ON
	uint8_t currentRxTxState = PHY_TRX_OFF;
	
	//message received
	//norace MPDU rxmpdu;
	MPDU *rxmpdu_ptr;

  
  error_t sendErr = SUCCESS;

  
  
  /** TRUE if we are to use CCA when sending the current packet */
  norace bool ccaOn;
  
  /****************** Prototypes ****************/
  task void startDone_task();
  task void startDone_task();
  task void stopDone_task();
  task void sendDone_task();
  
  void shutdown();



/***************** Init Commands ****************/
  command error_t Init.init() {
  
  //atomic rxmpdu_ptr = &rxmpdu;
  
  //TODO
  /*
  	//PHY PIB initialization
	//phy_PIB.phyCurrentChannel=INIT_CURRENTCHANNEL;
	phy_PIB.phyCurrentChannel=LOGICAL_CHANNEL;
	phy_PIB.phyChannelsSupported=INIT_CHANNELSSUPPORTED;
	phy_PIB.phyTransmitPower=INIT_TRANSMITPOWER;
	phy_PIB.phyCcaMode=INIT_CCA_MODE;
  */
  
    return SUCCESS;
  }


  /***************** SplitControl Commands ****************/
  command error_t SplitControl.start() {
   
		//arrancar o controlo
   
      call CC2420Power.startVReg();
	  
	  	
      return SUCCESS;
    

  }

  command error_t SplitControl.stop() {
 
    return EBUSY;
  }

  /***************** Send Commands ****************/


    async event void Sendframe.sendDone(error_t error )
	{
	
	    atomic sendErr = error;
		post sendDone_task();
	
	}
  
  
  

  /**************** Events ****************/
  async event void CC2420Power.startVRegDone() {
    call Resource.request();

  }
  
  event void Resource.granted() {
    call CC2420Power.startOscillator();
  }

  async event void CC2420Power.startOscillatorDone() {
    post startDone_task();
  }
  
  
  
  /***************** Tasks ****************/
  task void sendDone_task() {
    error_t packetErr;
    atomic packetErr = sendErr;
	
   // signal Send.sendDone( m_msg, packetErr );
  }

  task void startDone_task() {
    call SubControl.start();
    call CC2420Power.rxOn();
    call Resource.release();
  
    signal SplitControl.startDone( SUCCESS );
  }
  
  task void stopDone_task() {
    
    signal SplitControl.stopDone( SUCCESS );
  }
  
  
  /***************** Functions ****************/
  /**
   * Shut down all sub-components and turn off the radio
   */
  void shutdown() {
    call SubControl.stop();
    call CC2420Power.stopVReg();
    post stopDone_task();
  }

  /***************** Defaults ***************/
  default event void SplitControl.startDone(error_t error) {
  }
  
  default event void SplitControl.stopDone(error_t error) {
  }
  
  
  
  async event void Receiveframe.receive(uint8_t* frame, uint8_t rssi)
  {
  
    rxmpdu_ptr=(MPDU*)frame;
		
	signal PD_DATA.indication(rxmpdu_ptr->length,(uint8_t*)rxmpdu_ptr, rssi);
  /*
  printfUART("n %i\n", TOS_NODE_ID); 
  
	printfUART("l %i\n", rxmpdu_ptr->length); 
  printfUART("fc1 %i\n", rxmpdu_ptr->frame_control1); 
  printfUART("fc2 %i\n", rxmpdu_ptr->frame_control2); 
	printfUART("seq %i\n", rxmpdu_ptr->seq_num); 
  
  for (i=0;i<120;i++)
  {
	printfUART("d %i %x\n",i, rxmpdu_ptr->data[i]); 
  
  }
  */
  
  
  }
  
  
  
  event void CC2420Config.syncDone( error_t error )
  {
  
  
  
  return;
  }
  
  
/*****************************************************************************************************/  
/**************************************PD-DATA********************************************************/
/*****************************************************************************************************/  


async command error_t PD_DATA.request(uint8_t psduLength, uint8_t* psdu) {
	
	
	call Sendframe.send(psdu,psduLength);


	return SUCCESS;
}


/*****************************************************************************************************/  
/********************************************PLME-ED**************************************************/
/*****************************************************************************************************/  

command error_t PLME_ED.request(){
	//MAC asking for energy detection
	//TODO
	
	return SUCCESS;
}

/*****************************************************************************************************/  
/********************************************PLME-CCA*************************************************/
/*****************************************************************************************************/

command error_t PLME_CCA.request(){
//MAC asking for CCA
//TODO
		
	
	return SUCCESS;
}
 
/*****************************************************************************************************/  
/********************************************PLME-GET*************************************************/
/*****************************************************************************************************/

command error_t PLME_GET.request(uint8_t PIBAttribute){
//MAC asking for PIBAttribute value
  switch(PIBAttribute)
		{
			case PHYCURRENTCHANNEL:
				signal PLME_GET.confirm(PHY_SUCCESS, PIBAttribute, phy_PIB.phyCurrentChannel);
				break;

			case PHYCHANNELSSUPPORTED:
				signal PLME_GET.confirm(PHY_SUCCESS, PIBAttribute, phy_PIB.phyChannelsSupported);
				break;

			case PHYTRANSMITPOWER:
				signal PLME_GET.confirm(PHY_SUCCESS, PIBAttribute, phy_PIB.phyTransmitPower);
				break;
			case PHYCCAMODE:
				signal PLME_GET.confirm(PHY_SUCCESS, PIBAttribute, phy_PIB.phyCcaMode);
				break;
			default:
				signal PLME_GET.confirm(PHY_UNSUPPORTED_ATTRIBUTE, PIBAttribute, 0x00);
				break;
		}
		
  
  return SUCCESS;
  }
  
/*****************************************************************************************************/  
/********************************************PLME-SET*************************************************/
/*****************************************************************************************************/
command error_t PLME_SET.request(uint8_t PIBAttribute, uint8_t PIBAttributeValue){
  

	  //MAC is demanding for PHY to write the indicated PIB value
	  switch(PIBAttribute)
			{
				case PHYCURRENTCHANNEL:
					
					phy_PIB.phyCurrentChannel = PIBAttributeValue;
					
					call CC2420Config.setChannel(phy_PIB.phyCurrentChannel);
					
					call CC2420Config.sync();
					
					//TunePreset(phy_PIB.phyCurrentChannel);
					signal PLME_SET.confirm(PHY_SUCCESS, PIBAttribute);
					break;
	
				case PHYCHANNELSSUPPORTED:
					phy_PIB.phyChannelsSupported = PIBAttributeValue;
					signal PLME_SET.confirm(PHY_SUCCESS, PIBAttribute);
					break;
	
				case PHYTRANSMITPOWER:
					phy_PIB.phyTransmitPower= PIBAttributeValue;
					//SetRFPower(phy_PIB.phyTransmitPower);
					signal PLME_SET.confirm(PHY_SUCCESS, PIBAttribute);
					break;
				case PHYCCAMODE:
					phy_PIB.phyCcaMode= PIBAttributeValue;
					signal PLME_SET.confirm(PHY_SUCCESS, PIBAttribute);
					break;
				default:
					signal PLME_SET.confirm(PHY_UNSUPPORTED_ATTRIBUTE, PIBAttribute);
					break;
			}
	  return SUCCESS;
}  

/*****************************************************************************************************/  
/**********************************PLME_SET_TRX_STATE*************************************************/
/*****************************************************************************************************/


async command error_t PLME_SET_TRX_STATE.request(uint8_t state){


return SUCCESS;

}



}

