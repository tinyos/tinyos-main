/**
 * MLME-SYNC-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */

interface MLME_SYNC
{ 
//sd pag 105
  command error_t request(uint8_t logical_channel,uint8_t track_beacon);

}
