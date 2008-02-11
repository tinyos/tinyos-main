/**
 * MLME-SYNC-LOSS-Service Access Point
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author IPP HURRAY http://www.open-zb.net
 * @author Andre Cunha
 *
 *
 */

interface MLME_SYNC_LOSS
{ 
//pag 105
   event error_t indication(uint8_t LossReason);
}
