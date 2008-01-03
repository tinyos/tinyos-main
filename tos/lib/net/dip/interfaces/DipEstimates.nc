
#include <Dip.h>

interface DipEstimates {
  command dip_estimate_t* getEstimates();
  command void decEstimateByIndex(dip_index_t i);
  command void decEstimateByKey(dip_key_t key);
  command dip_hashlen_t estimateToHashlength(dip_estimate_t est);
  command dip_estimate_t hashlengthToEstimate(dip_hashlen_t len);
  // special event to reset trickle timer too
  command void setDataEstimate(dip_key_t key);
  command void setVectorEstimate(dip_key_t key);
  command void setSummaryEstimateByIndex(dip_index_t ind,
					 dip_estimate_t est);
}
