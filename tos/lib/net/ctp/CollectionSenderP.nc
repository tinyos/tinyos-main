#include "Collection.h"

generic configuration 
CollectionSenderP(collection_id_t collectid, uint8_t clientid) {
  provides {
    interface Send;
    interface Packet;
  }
}

implementation {
  components CollectionC as Collector;
  components new CollectionIdP(collectid);
  
  Send = Collector.Send[clientid];
  Packet = Collector.Packet;
  Collector.CollectionId[clientid] -> CollectionIdP;
}
