#include "IPDispatch.h"
#include "BlipStatistics.h"

module IPDispatchC {
  provides {
    interface SplitControl;
    interface IPLower;
    interface BlipStatistics<ip_statistics_t>;
  }
} implementation {

  command error_t SplitControl.start() {
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    return SUCCESS;
  }

  command error_t IPLower.send(struct ieee154_frame_addr *frame_addr,
                               struct ip6_packet *msg,
                               void  *data) {
    return SUCCESS;
  }

  command void BlipStatistics.get(ip_statistics_t *statistics) {
  }

  command void BlipStatistics.clear() {
  }

}
