
#include <DIP.h>

module DIPVectorP {
  provides interface DIPDecision;

  uses interface DIPSend as VectorSend;
  uses interface DIPReceive as VectorReceive;

  uses interface DIPHelp;
  uses interface DIPEstimates;

  uses interface Random;
}

implementation {
  uint8_t commRate = 0;
  typedef struct pairs_t {
    dip_estimate_t estimate;
    dip_key_t key;
  } pairs_t;
  pairs_t pairs[UQCOUNT_DIP]; // This is large memory footprint

  int myComparator(const void* a, const void* b);
  void randomizeRun(pairs_t* localPairs, dip_index_t length);

  command uint8_t DIPDecision.getCommRate() {
    return commRate;
  }

  command void DIPDecision.resetCommRate() {
    commRate = 0;
  }

  command error_t DIPDecision.send() {
    dip_index_t i, j, r;
    dip_key_t sendkey;
    dip_estimate_t* ests;

    dip_msg_t* dmsg;
    dip_vector_msg_t* dvmsg;

    dmsg = call VectorSend.getPayloadPtr();
    if(dmsg == NULL) {
      return FAIL;
    }

    ests = call DIPEstimates.getEstimates();
    // get all estimates and sort
    for(i = 0; i < UQCOUNT_DIP; i++) {
      pairs[i].key = call DIPHelp.indexToKey(i);
      pairs[i].estimate = ests[i];
    }
    qsort(pairs, UQCOUNT_DIP, sizeof(pairs_t), myComparator);
    j = pairs[0].estimate;
    r = 0;
    for(i = 0; i < UQCOUNT_DIP; i++) {
      if(pairs[i].estimate < j) {
	randomizeRun(&pairs[r], i - r);
	j = pairs[i].estimate;
	r = i;
      }
    }
    // randomize the last set
    randomizeRun(&pairs[r], UQCOUNT_DIP - r);

    // fill up the packet
    dmsg->type = ID_DIP_VECTOR;
    dvmsg = (dip_vector_msg_t*) dmsg->content;
    dvmsg->unitLen = DIP_VECTOR_ENTRIES_PER_PACKET;
    for(i = 0, j = 0;
	i < DIP_VECTOR_ENTRIES_PER_PACKET;
	i += 2, j++) {
      sendkey = pairs[j].key;
      dvmsg->vector[i] = sendkey;
      dvmsg->vector[i+1] = call DIPHelp.keyToVersion(sendkey);
      // adjust estimate
      call DIPEstimates.decEstimateByKey(sendkey);
    }

    return call VectorSend.send(sizeof(dip_msg_t) + sizeof(dip_vector_msg_t) +
				(DIP_VECTOR_ENTRIES_PER_PACKET * sizeof(uint32_t)));
  }

  event void VectorReceive.receive(void* payload, uint8_t len) {
    dip_vector_msg_t* dvmsg;
    uint8_t unitlen;

    uint8_t i;
    dip_key_t vectorkey;
    dip_version_t vectorver;
    dip_version_t myver;

    commRate = commRate + 1;
    dvmsg = (dip_vector_msg_t*) payload;
    unitlen = dvmsg->unitLen;

    for(i = 0; i < unitlen; i += 2) {
      vectorkey = dvmsg->vector[i];
      vectorver = dvmsg->vector[i+1];
      myver = call DIPHelp.keyToVersion(vectorkey);

      // TODO: handle the invalid versions
      if(myver < vectorver) {
	call DIPEstimates.setVectorEstimate(vectorkey);
      }
      else if(myver > vectorver) {
	call DIPEstimates.setDataEstimate(vectorkey);
      }
      else if(myver == vectorver) {
	call DIPEstimates.decEstimateByKey(vectorkey);
      }
    }

  }

  int myComparator(const void* a, const void* b) {
    const pairs_t *x = (const pairs_t *) a;
    const pairs_t *y = (const pairs_t *) b;
    if( x->estimate < y->estimate ) { return 1; }
    if( x->estimate > y->estimate ) { return -1; }
    return 0;
  }

  void randomizeRun(pairs_t* localPairs, dip_index_t length) {
    dip_index_t i,j;
    dip_index_t rLength = length;
    pairs_t temp;

    // don't move the last one
    for(i = 0; i < length - 1; i++, rLength--) {
      j = i + (call Random.rand16() % rLength);
      temp.key = localPairs[i].key;
      temp.estimate = localPairs[i].estimate;
      localPairs[i].key = localPairs[j].key;
      localPairs[i].estimate = localPairs[j].estimate;
      localPairs[j].key = temp.key;
      localPairs[j].estimate = temp.estimate;
    }
  }

}
