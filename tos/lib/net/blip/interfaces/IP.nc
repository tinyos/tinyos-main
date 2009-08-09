
interface IP {

  /*
   * sends the message with the headers and payload given.  Things
   * which we know how to compress should be part of the data passed
   * in as headers; things which we cannot compress must be passed as
   * payload.

   * the interface is this way so that the stack may insert extra
   * (routing, snooping) headers between the two sections.
   * once the call returns, the stack has no claim on the buffer
   * pointed to
   */ 
  command error_t send(struct split_ip_msg *msg);

  command error_t bareSend(struct split_ip_msg *msg, 
                           struct ip6_route *route,
                           int flags);

  /*
   * indicate that the stack has finished writing data into the
   * receive buffer. 
   */
  event void recv(struct ip6_hdr *iph, void *payload, struct ip_metadata *meta);

}
