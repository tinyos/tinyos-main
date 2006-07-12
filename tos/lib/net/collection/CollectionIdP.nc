#include "Collection.h"

generic module CollectionIdP(collection_id_t collectid) {
  provides interface CollectionId;
}

implementation {
  command collection_id_t CollectionId.fetch() {
    return collectid;
  }
}
