
#include <lib6lowpan/ip.h>
#include "IPDispatch.h"

interface IPLower {

  /*
   * Sends the message with the headers and payload given. Things
   * which we know how to compress should be part of the data passed
   * in as headers; things which we cannot compress must be passed as
   * payload.

   * The interface is this way so that the stack may insert extra
   * (routing, snooping) headers between the two sections.
   * once the call returns, the stack has no claim on the buffer
   * pointed to.
   */
  command error_t send(struct ieee154_frame_addr *next_hop,
                       struct ip6_packet *msg,
                       void *data);

  event void sendDone(struct send_info *status);

  /*
   * Indicate that the stack has finished writing data into the
   * receive buffer.
   */
  event void recv(struct ip6_hdr *iph,
                  void *payload,
                  struct ip6_metadata *meta);

}
