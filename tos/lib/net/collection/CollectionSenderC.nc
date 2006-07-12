/**
 * The virtualized collection sender abstraction.
 *
 * @author Kyle Jamieson
 * @author Philip Levis
 * @date April 25 2006
 * @see TinyOS Net2-WG
 */

#include "Collection.h"
#include "TreeCollection.h"

generic configuration CollectionSenderC(collection_id_t collectid) {
  provides {
    interface Send;
    interface Packet;
  }
}

implementation {
  components new CollectionSenderP(collectid, unique(UQ_COLLECTION_CLIENT));
  Send = CollectionSenderP;
  Packet = CollectionSenderP;
}
