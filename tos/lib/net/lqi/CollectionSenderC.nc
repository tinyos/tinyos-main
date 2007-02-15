/**
 * The virtualized collection sender abstraction.
 *
 * @author Kyle Jamieson
 * @author Philip Levis
 * @date April 25 2006
 * @see TinyOS Net2-WG
 */

#include <Collection.h>

generic configuration CollectionSenderC(collection_id_t collectid) {
  provides {
    interface Send;
    interface Packet;
  }
}
implementation {
  components CollectionC as Router;
  Send = Router;
  Packet = Router;
}
