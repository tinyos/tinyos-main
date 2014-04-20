/**
 * Internal interface for the CC2420 to get portions of a packet.
 * @author David Moss
 */
 
interface CC2420PacketBody {

  /**
   * @return pointer to the cc2420_header_t of the given message
   */
  async command tossim_header_t *getHeader(message_t *msg);
  
  /**
   * @return pointer to the cc2420_metadata_t of the given message
   */
  async command tossim_metadata_t *getMetadata(message_t *msg);
  
}

