
#include <Dhv.h>

interface DhvEstimates {
  command dhv_estimate_t* getEstimates();
  command void decEstimateByIndex(dhv_index_t i);
  command void decEstimateByKey(dhv_key_t key);
  command dhv_hashlen_t estimateToHashlength(dhv_estimate_t est);
  command dhv_estimate_t hashlengthToEstimate(dhv_hashlen_t len);
  // special event to reset trickle timer too
  command void setDataEstimate(dhv_key_t key);
  command void setVectorEstimate(dhv_key_t key);
  command void setSummaryEstimateByIndex(dhv_index_t ind,
					 dhv_estimate_t est);
}
