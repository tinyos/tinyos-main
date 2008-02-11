/**
 * Low-level abstraction for the receive path implementaiton of the
 * ChipCon CC2420 radio.
 *
 * @author 
 * @version 
 */

interface Receiveframe {

  /**
   * Signal that a message has been received
   */
  async event void receive(uint8_t* frame, uint8_t rssi);

}
