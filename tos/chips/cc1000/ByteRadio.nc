/* $Id: ByteRadio.nc,v 1.4 2006-12-12 18:23:05 vlahan Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Radio logic is split between Csma (media-access control, low-power
 * listening and general control) and SendReceive (packet reception and
 * transmission). This interface specifies the interaction between these
 * two components.
 *
 * @author David Gay
 */
  
interface ByteRadio
{
  /**
   * SendReceive wants to send a packet.
   * @param msg Message to be sent.
   */
  event void rts(message_t *msg);

  /**
   * Access to the media granted. Start sending. SendReceive must signal
   * sendDone when transmission is complete. Note: the media-access-contro
   * layer must have enabled listening before calling cts().
   */
  async command void cts();

  /**
   * Between the rts() and sendDone() events, this must return the
   * message under transmission.
   * @return Message being transmitted.
   */
  async command message_t *getTxMessage();

  /**
   * Transmission complete.
   */
  async event void sendDone();

  /**
   * Set message preamble length.
   * @param bytes Preamble length in bytes
   */
  async command void setPreambleLength(uint16_t bytes);

  /**
   * Get message preamble length.
   * @return Preamble length in bytes
   */
  async command uint16_t getPreambleLength();

  /**
   * Enable listening for incoming packets.
   */
  async command void listen();

  /**
   * Disable listening for incoming packets.
   */
  async command void off();

  /**
   * SendReceive signals this event for every radio-byte-time while
   * listening is enabled and a message isn't being received or
   * transmitted.
   * @param preamble TRUE if a message preamble byte has been received
   */
  async event void idleByte(bool preamble);

  /**
   * Detect if SendReceive is attempting to sync with an incoming packet.
   * During sync, idleByte events are not signaled. If sync is successful,
   * an rx() event will be signaled, if it fails, idleByte events will
   * resume. If syncing() returns TRUE, the last idleByte() event must
   * have had preamble = TRUE.
   *
   * @return TRUE if a sync attempt is in progress, FALSE if not.
   */
  async command bool syncing();

  /**
   * A message is being received
   */
  async event void rx();

  /**
   * Message reception is complete.
   */
  async event void rxDone();
}
