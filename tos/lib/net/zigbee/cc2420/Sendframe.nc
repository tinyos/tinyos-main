/**
 * Low-level abstraction for the transmit path implementaiton of the
 * ChipCon CC2420 radio.
 *
 * @author 
 * @version 
 */

interface Sendframe {

  /**
   * Send a message

   * @return SUCCESS if the request was accepted, FAIL otherwise.
   */
  async command error_t send(uint8_t* frame, uint8_t frame_length);
  
  /**
   * Signal that a message has been sent
   */
  async event void sendDone(error_t error );

}

