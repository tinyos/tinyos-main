/*
 * MLME-BEACON-NOTIFY-Service Access Point
 * std pag 75
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 */
includes mac_const;

interface MLME_BEACON_NOTIFY
{ 
	event error_t indication(uint8_t BSN,PANDescriptor pan_descriptor, uint8_t PenAddrSpec, uint8_t AddrList, uint8_t sduLength, uint8_t sdu[]);
 
}
