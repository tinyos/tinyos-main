/**
 * Dummy module for Packet Link layer
 * @author David Moss
 * @author Jon Wyant
 */

module PacketLinkDummyP {
  provides {
    interface PacketLink;
  }
  
  uses {
    interface PacketAcknowledgements;
  }
}

implementation {
  
  /***************** PacketLink Commands ***************/
  /**
   * Set the maximum number of times attempt message delivery
   * Default is 0
   * @param msg
   * @param maxRetries the maximum number of attempts to deliver
   *     the message
   */
  command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries) {
  }

  /**
   * Set a delay between each retry attempt
   * @param msg
   * @param retryDelay the delay betweeen retry attempts, in milliseconds
   */
  command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay) {
  }

  /** 
   * @return the maximum number of retry attempts for this message
   */
  command uint16_t PacketLink.getRetries(message_t *msg) {
    return 0;
  }

  /**
   * @return the delay between retry attempts in ms for this message
   */
  command uint16_t PacketLink.getRetryDelay(message_t *msg) {
    return 0;
  }

  /**
   * @return TRUE if the message was delivered.
   *     This should always be TRUE if the message was sent to the
   *     AM_BROADCAST_ADDR
   */
  command bool PacketLink.wasDelivered(message_t *msg) {
    return call PacketAcknowledgements.wasAcked(msg);
  }
}

