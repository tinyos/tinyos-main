/**
 * Allows protocol layers above the routing layer to perform data
 * aggregation or make application-specific decisions on whether to
 * forward via the return value of the forward event.
 *
 * @author Philip Levis
 * @author Kyle Jamieson
 * @version $Id: Intercept.nc,v 1.5 2008-02-09 05:44:09 gnawali Exp $
 * @see TEP 116: Packet Protocols, TEP 119: Collection
 */

#include <TinyError.h>
#include <message.h>

interface Intercept {
  /**
   * Signals that a message has been received, which is supposed to be
   * forwarded to another destination. 
   *
   * @param msg The complete message received.
   *
   * @param payload The payload portion of the packet for this
   * protocol layer.
   *
   * @param len The length of the payload buffer.
   *
   * @return TRUE indicates the packet should be forwarded, FALSE
   * indicates that it should not be forwarded.
   *
   */
  event bool forward(message_t* msg, void* payload, uint8_t len);
}
