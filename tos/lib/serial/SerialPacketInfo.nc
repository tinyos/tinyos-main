/**
 * Accessor methods used by a serial dispatcher to communicate with various
 * message_t link formats over a serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 */

interface SerialPacketInfo {
  /**
   * Get the offset into a message_t where the header information begins.
   * @return Returns the offset.
   */
  async command uint8_t offset();
  /**
   * Get the size of the datalink packet embedded in the message_t, in bytes. 
   * This is the sum of the payload (upperLen) and the size of the link header.
   * @param msg A pointer to the message_t to interrogate. (unused)
   * @param upperLen The size of the payload.
   * @return Returns the size of the datalink packet.
   */
  async command uint8_t dataLinkLength(message_t* msg, uint8_t upperLen);
  /**
   * Get the size of the payload (in bytes) given the size of the datalink
   * packet (dataLinkLen) embedded in the message_t.
   * @param msg A pointer to the message_t to interrogate. (unused)
   * @param dataLinkLength The size of the datalink packet.
   * @return Returns the size of the payload.
   */
  async command uint8_t upperLength(message_t* msg, uint8_t dataLinkLen);
}
