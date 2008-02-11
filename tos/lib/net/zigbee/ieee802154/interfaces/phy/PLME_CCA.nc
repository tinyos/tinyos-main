/**
 * Physical Layer Management Entity-Service Access Point
 * PLME-SAP - PLME-CCA
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

interface PLME_CCA
{ 
/*PLME_CCA*/

  command error_t request();

  event error_t confirm(uint8_t status);

}
