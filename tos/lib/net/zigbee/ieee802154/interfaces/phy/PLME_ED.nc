/**
 * Physical Layer Management Entity-Service Access Point
 * PLME-SAP - PLME-ED
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 */

interface PLME_ED
{ 
/*PLME_ED*/

  command error_t request();

  event error_t confirm(uint8_t status,int8_t EnergyLevel);

}
