
#include <DIP.h>

module DIPLogicP {
  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];
  provides interface DIPEstimates;

  provides interface Init;
  provides interface StdControl;

  uses interface Boot;
  uses interface DIPTrickleTimer;
  uses interface DisseminationUpdate<dip_data_t> as VersionUpdate[dip_key_t key];
  uses interface DIPDecision as DIPDataDecision;
  uses interface DIPDecision as DIPVectorDecision;
  uses interface DIPDecision as DIPSummaryDecision;
  uses interface DIPHelp;
}

implementation {
  uint32_t windowSize;
  dip_hashlen_t totalPossible;

  dip_estimate_t estimates[UQCOUNT_DIP];

  uint16_t diplog(uint16_t base, uint16_t num);
  uint16_t dipexp(uint16_t base, uint16_t expt);
  dip_estimate_t getDataEstimate(dip_hashlen_t len);
  dip_estimate_t getMaxEstimate(dip_hashlen_t len);
  uint8_t sendDecision();

  command error_t Init.init() {
    windowSize = DIP_TAU_HIGH;
    DIP_DATA_ESTIMATE = getDataEstimate(UQCOUNT_DIP);
    DIP_MAX_ESTIMATE = getMaxEstimate(UQCOUNT_DIP);
    DIP_VECTOR_ESTIMATE = DIP_DATA_ESTIMATE - 1;
    totalPossible = call DIPEstimates.estimateToHashlength(0);
    dbg("DIPLogicP", "Real Total: %u, DIP Total: %u\n", UQCOUNT_DIP, totalPossible);
    if(totalPossible < UQCOUNT_DIP) {
      DIP_DATA_ESTIMATE++;
      DIP_MAX_ESTIMATE++;
      DIP_VECTOR_ESTIMATE++;
      totalPossible = call DIPEstimates.estimateToHashlength(0);
    }
    dbg("DIPLogicP", "Real Total: %u, DIP New Total: %u\n", UQCOUNT_DIP, totalPossible);
    dbg("DIPLogicP","DATA_ESTIMATE initialized to %u\n", DIP_DATA_ESTIMATE);
    dbg("DIPLogicP","MAX_ESTIMATE initialized to %u\n", DIP_MAX_ESTIMATE);
    dbg("DIPLogicP","VECT_ESTIMATE initialized to %u\n", DIP_VECTOR_ESTIMATE);
    dbg("DIPLogicP","DIP ready\n");

    return SUCCESS;
  }

  event void Boot.booted() {

  }

  command error_t StdControl.start() {
    return call DIPTrickleTimer.start();
  }

  command error_t StdControl.stop() {
    call DIPTrickleTimer.stop();
    return SUCCESS;
  }

  command void DisseminationUpdate.change[dip_key_t key](dip_data_t* val) {
    dip_index_t i;

    dbg("DIPLogicP","App notified key %x is new\n", key);
    i = call DIPHelp.keyToIndex(key);
    estimates[i] = DIP_DATA_ESTIMATE;
    call VersionUpdate.change[key](val);
    call DIPTrickleTimer.reset();
  }

  event uint32_t DIPTrickleTimer.requestWindowSize() {
    dip_index_t i;
    dip_estimate_t max = 0;

    for(i = 0; i < UQCOUNT_DIP; i++) {
      if(estimates[i] > 0) {
	max = estimates[i];
	windowSize = DIP_TAU_LOW;
	break;
      }
    }
    if(max == 0) {
      windowSize = windowSize << 1;
      if(windowSize > DIP_TAU_HIGH) {
	windowSize = DIP_TAU_HIGH;
      }
    }

    dbg("DIPLogicP", "Window size requested, give %u\n", windowSize);
    return windowSize;
  }

  event void DIPTrickleTimer.fired() {
    dip_index_t i;
    uint8_t decision;

    dbg("DIPLogicP","Trickle Timer fired!\n");

    for(i = 0; i < UQCOUNT_DIP; i++) {
      dbg("DIPLogicP","Index-%u Estimate-%u\n", i, estimates[i]);
    }

    decision = sendDecision();

    switch(decision) {
    case ID_DIP_INVALID:
      dbg("DIPLogicP", "Decision to SUPPRESS\n");
      break;
    case ID_DIP_SUMMARY:
      dbg("DIPLogicP", "Decision to SUMMARY\n");
      call DIPSummaryDecision.send();
      break;
    case ID_DIP_VECTOR:
      dbg("DIPLogicP", "Decision to VECTOR\n");
      call DIPVectorDecision.send();
      break;
    case ID_DIP_DATA:
      dbg("DIPLogicP", "Decision to DATA\n");
      call DIPDataDecision.send();
      break;
    }
    call DIPDataDecision.resetCommRate();
    call DIPVectorDecision.resetCommRate();
    call DIPSummaryDecision.resetCommRate();
  }

  command dip_estimate_t* DIPEstimates.getEstimates() {
    return estimates;
  }

  command void DIPEstimates.decEstimateByIndex(dip_index_t i) {
    if(estimates[i] != 0) {
      estimates[i] = estimates[i] - 1;
    }
  }

  command void DIPEstimates.decEstimateByKey(dip_key_t key) {
    dip_index_t i;

    i = call DIPHelp.keyToIndex(key);
    call DIPEstimates.decEstimateByIndex(i);
  }

  command dip_estimate_t DIPEstimates.hashlengthToEstimate(dip_hashlen_t len) {
    if(len == UQCOUNT_DIP) {
      len = totalPossible;
    }
    return DIP_MAX_ESTIMATE - diplog(DIP_SUMMARY_VALUES_PER_PACKET, len);
  }

  command dip_hashlen_t DIPEstimates.estimateToHashlength(dip_estimate_t est) {
    uint8_t expt, base;
    uint16_t val;

    base = DIP_SUMMARY_VALUES_PER_PACKET;
    expt = DIP_MAX_ESTIMATE - est;
    val = dipexp(base, expt);
    
    if(val > UQCOUNT_DIP) { // bring length back down if over UQCOUNT_DIP
      val = UQCOUNT_DIP;
    }

    return val;
  }

  /* Calculation functions */
  uint16_t diplog(uint16_t base, uint16_t num) {
    uint8_t counter;

    counter = 0;
    while(num != 0) {
      num = num / base;
      counter++;
    }
    return counter - 1;
  }

  command void DIPEstimates.setDataEstimate(dip_key_t key) {
    dip_index_t i;

    i = call DIPHelp.keyToIndex(key);
    estimates[i] = DIP_DATA_ESTIMATE;
    call DIPTrickleTimer.reset();
  }

  command void DIPEstimates.setVectorEstimate(dip_key_t key) {
    dip_index_t i;
    
    i = call DIPHelp.keyToIndex(key);
    if(estimates[i] < DIP_VECTOR_ESTIMATE) {
      estimates[i] = DIP_VECTOR_ESTIMATE;
    }
    call DIPTrickleTimer.reset();
  }

  command void DIPEstimates.setSummaryEstimateByIndex(dip_index_t ind,
						      dip_estimate_t est) {
    if(estimates[ind] < est) {
      estimates[ind] = est;
    }
    call DIPTrickleTimer.reset();
  }

  uint16_t dipexp(uint16_t base, uint16_t expt) {
    uint16_t ans;

    ans = 1;
    while(expt > 0) {
      if((expt & 1) == 0) {
	base = base * base;
	expt = expt >> 1;
      }
      else {
	ans = ans * base;
	expt = expt - 1;
      }
    }
    return ans;
  }

  dip_estimate_t getDataEstimate(dip_hashlen_t len) {
    dip_estimate_t h_total;
    dip_estimate_t v_total;

    h_total = diplog(DIP_SUMMARY_VALUES_PER_PACKET, len);
    v_total = diplog(DIP_SUMMARY_VALUES_PER_PACKET,
		     DIP_VECTOR_VALUES_PER_PACKET);

    return h_total - v_total + 1;
  }

  dip_estimate_t getMaxEstimate(dip_hashlen_t len) {
    return diplog(DIP_SUMMARY_VALUES_PER_PACKET, len);
  }
  
  uint8_t sendDecision() {
    dip_estimate_t highEst;
    dip_estimate_t est;
    uint8_t dataCommRate;
    uint8_t vectorCommRate;
    uint8_t summaryCommRate;
    dip_estimate_t* allEsts;
    dip_index_t i;

    uint16_t E, D, L, V, C;

    allEsts = call DIPEstimates.getEstimates();
    highEst = 0;
    dataCommRate = call DIPDataDecision.getCommRate();
    vectorCommRate = call DIPVectorDecision.getCommRate();
    summaryCommRate = call DIPSummaryDecision.getCommRate();

    if(dataCommRate > 1) {
      dbg("DIPLogicP", "Heard data\n");
      return ID_DIP_INVALID;
    }

    // if there is an estimate with highest estimate value, send
    for(i = 0; i < UQCOUNT_DIP; i++) {
      est = allEsts[i];
      if(est >= DIP_DATA_ESTIMATE) { return ID_DIP_DATA; }
      if(est > highEst) { highEst = est; };
    }

    // didn't send or hear data at this point
    if(vectorCommRate + summaryCommRate > 1) {
      dbg("DIPLogicP", "Heard an advertisement\n");
      return ID_DIP_INVALID;
    }

    // corner case, if hash is too short
    if(call DIPEstimates.estimateToHashlength(highEst) <= DIP_VECTOR_VALUES_PER_PACKET) {
      return ID_DIP_VECTOR;
    }

    // now we make the DIP decision
    C = dataCommRate + vectorCommRate + summaryCommRate;
    if(C == 0) C = 1; // don't want to divide by zero
    E = highEst;
    D = DIP_DATA_ESTIMATE;
    L = call DIPEstimates.estimateToHashlength(E);
    V = DIP_VECTOR_VALUES_PER_PACKET;

    dbg("DIPLogicP", "D=%u, E=%u, L=%u, V=%u, C=%u\n", D, E, L, V, C);
    if((D - E) < (L / (C * V))) {
      return ID_DIP_SUMMARY;
    }
    return ID_DIP_VECTOR;
  }

}
