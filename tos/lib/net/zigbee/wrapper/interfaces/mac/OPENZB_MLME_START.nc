/**
 * MLME-START-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Ricardo Severino
 *
 *
 */

interface OPENZB_MLME_START
{ 

  //request for the device to start using new superframe configuration
  command error_t request(uint32_t PANId, uint8_t LogicalChannel, uint8_t BeaconOrder, uint8_t SuperframeOrder,uint8_t PANCoordinator,uint8_t BatteryLifeExtension,uint8_t CoordRealignment,uint8_t SecurityEnable,uint32_t StartTime);
  
  event error_t confirm(uint8_t status);
  
}
