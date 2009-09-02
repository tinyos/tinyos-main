/**
 * MLME-SCAN-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Ricardo Severino
 *
 *
 */

interface OPENZB_MLME_SCAN
{ 

  command error_t request(uint8_t ScanType, uint32_t ScanChannels, uint8_t ScanDuration);
	
  event error_t confirm(uint8_t status,uint8_t ScanType, uint32_t UnscannedChannels, uint8_t ResultListSize, uint8_t EnergyDetectList[], SCAN_PANDescriptor PANDescriptorList[]);
																						//NEED to explain the implementation
																						//Eache value in sequencial to the scanned channels
	}
