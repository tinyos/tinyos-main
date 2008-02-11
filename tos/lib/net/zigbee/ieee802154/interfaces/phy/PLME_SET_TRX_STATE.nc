/**
 * Physical Layer Management Entity-Service Access Point
 * PLME-SAP - PLME-SET_TRX_STATE
 *
 * @author IPP HURRAY http://www.hurray.isep.ipp.pt/art-wise
 * @author Andre Cunha
 *
 */

interface PLME_SET_TRX_STATE
{ 
/*PLME_SET_TRX_STATE*/

  async command error_t request(uint8_t state);

  async event error_t confirm(uint8_t status);

}
