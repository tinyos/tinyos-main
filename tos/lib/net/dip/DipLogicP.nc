
#include <Dip.h>

module DipLogicP {
  provides interface DisseminationUpdate<dip_data_t>[dip_key_t key];
  provides interface DipEstimates;

  provides interface Init;
  provides interface StdControl;

  uses interface Boot;
  uses interface DipTrickleTimer;
  uses interface DisseminationUpdate<dip_data_t> as VersionUpdate[dip_key_t key];
  uses interface DipDecision as DipDataDecision;
  uses interface DipDecision as DipVectorDecision;
  uses interface DipDecision as DipSummaryDecision;
  uses interface DipHelp;
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
    totalPossible = call DipEstimates.estimateToHashlength(0);
    dbg("DipLogicP", "Real Total: %u, Dip Total: %u\n", UQCOUNT_DIP, totalPossible);
    if(totalPossible < UQCOUNT_DIP) {
      DIP_DATA_ESTIMATE++;
      DIP_MAX_ESTIMATE++;
      DIP_VECTOR_ESTIMATE++;
      totalPossible = call DipEstimates.estimateToHashlength(0);
    }
    dbg("DipLogicP", "Real Total: %u, DIP New Total: %u\n", UQCOUNT_DIP, totalPossible);
    dbg("DipLogicP","DATA_ESTIMATE initialized to %u\n", DIP_DATA_ESTIMATE);
    dbg("DipLogicP","MAX_ESTIMATE initialized to %u\n", DIP_MAX_ESTIMATE);
    dbg("DipLogicP","VECT_ESTIMATE initialized to %u\n", DIP_VECTOR_ESTIMATE);
    dbg("DipLogicP","DIP ready\n");

    return SUCCESS;
  }

  event void Boot.booted() {

  }

  command error_t StdControl.start() {
    return call DipTrickleTimer.start();
  }

  command error_t StdControl.stop() {
    call DipTrickleTimer.stop();
    return SUCCESS;
  }

  command void DisseminationUpdate.change[dip_key_t key](dip_data_t* val) {
    dip_index_t i;

    dbg("DipLogicP","App notified key %x is new\n", key);
    i = call DipHelp.keyToIndex(key);
    estimates[i] = DIP_DATA_ESTIMATE;
    call VersionUpdate.change[key](val);
    call DipTrickleTimer.reset();
  }

  event uint32_t DipTrickleTimer.requestWindowSize() {
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

    dbg("DipLogicP", "Window size requested, give %u\n", windowSize);
    return windowSize;
  }

  event void DipTrickleTimer.fired() {
    dip_index_t i;
    uint8_t decision;

    dbg("DipLogicP","Trickle Timer fired!\n");

    for(i = 0; i < UQCOUNT_DIP; i++) {
      dbg("DipLogicP","Index-%u Estimate-%u\n", i, estimates[i]);
    }

    decision = sendDecision();

    switch(decision) {
    case ID_DIP_INVALID:
      dbg("DipLogicP", "Decision to SUPPRESS\n");
      break;
    case ID_DIP_SUMMARY:
      dbg("DipLogicP", "Decision to SUMMARY\n");
      call DipSummaryDecision.send();
      break;
    case ID_DIP_VECTOR:
      dbg("DipLogicP", "Decision to VECTOR\n");
      call DipVectorDecision.send();
      break;
    case ID_DIP_DATA:
      dbg("DipLogicP", "Decision to DATA\n");
      call DipDataDecision.send();
      break;
    }
    call DipDataDecision.resetCommRate();
    call DipVectorDecision.resetCommRate();
    call DipSummaryDecision.resetCommRate();
  }

  command dip_estimate_t* DipEstimates.getEstimates() {
    return estimates;
  }

  command void DipEstimates.decEstimateByIndex(dip_index_t i) {
    if(estimates[i] != 0) {
      estimates[i] = estimates[i] - 1;
    }
  }

  command void DipEstimates.decEstimateByKey(dip_key_t key) {
    dip_index_t i;

    i = call DipHelp.keyToIndex(key);
    call DipEstimates.decEstimateByIndex(i);
  }

  command dip_estimate_t DipEstimates.hashlengthToEstimate(dip_hashlen_t len) {
    if(len == UQCOUNT_DIP) {
      len = totalPossible;
    }
    return DIP_MAX_ESTIMATE - diplog(DIP_SUMMARY_VALUES_PER_PACKET, len);
  }

  command dip_hashlen_t DipEstimates.estimateToHashlength(dip_estimate_t est) {
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

  command void DipEstimates.setDataEstimate(dip_key_t key) {
    dip_index_t i;

    i = call DipHelp.keyToIndex(key);
    estimates[i] = DIP_DATA_ESTIMATE;
    call DipTrickleTimer.reset();
  }

  command void DipEstimates.setVectorEstimate(dip_key_t key) {
    dip_index_t i;
    
    i = call DipHelp.keyToIndex(key);
    if(estimates[i] < DIP_VECTOR_ESTIMATE) {
      estimates[i] = DIP_VECTOR_ESTIMATE;
    }
    call DipTrickleTimer.reset();
  }

  command void DipEstimates.setSummaryEstimateByIndex(dip_index_t ind,
						      dip_estimate_t est) {
    if(estimates[ind] < est) {
      estimates[ind] = est;
    }
    call DipTrickleTimer.reset();
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

    allEsts = call DipEstimates.getEstimates();
    highEst = 0;
    dataCommRate = call DipDataDecision.getCommRate();
    vectorCommRate = call DipVectorDecision.getCommRate();
    summaryCommRate = call DipSummaryDecision.getCommRate();

    if(dataCommRate > 1) {
      dbg("DipLogicP", "Heard data\n");
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
      dbg("DipLogicP", "Heard an advertisement\n");
      return ID_DIP_INVALID;
    }

    // corner case, if hash is too short
    if(call DipEstimates.estimateToHashlength(highEst) <= DIP_VECTOR_VALUES_PER_PACKET) {
      return ID_DIP_VECTOR;
    }

    // now we make the DIP decision
    C = dataCommRate + vectorCommRate + summaryCommRate;
    if(C == 0) C = 1; // don't want to divide by zero
    E = highEst;
    D = DIP_DATA_ESTIMATE;
    L = call DipEstimates.estimateToHashlength(E);
    V = DIP_VECTOR_VALUES_PER_PACKET;

    dbg("DipLogicP", "D=%u, E=%u, L=%u, V=%u, C=%u\n", D, E, L, V, C);
    if((D - E) < (L / (C * V))) {
      return ID_DIP_SUMMARY;
    }
    return ID_DIP_VECTOR;
  }

}
