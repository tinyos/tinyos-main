/**
 * The virtualized collection sender abstraction.
 *
 * @author Kyle Jamieson
 * @author Philip Levis
 * @date April 25 2006
 * @see TinyOS Net2-WG
 */

#include <Ctp.h>

generic configuration CollectionSenderC(collection_id_t collectid) {
  provides {
    interface Send;
    interface Packet;
  }
}
implementation {
  components new CollectionSenderP(collectid, unique(UQ_CTP_CLIENT));
  Send = CollectionSenderP;
  Packet = CollectionSenderP;
}
