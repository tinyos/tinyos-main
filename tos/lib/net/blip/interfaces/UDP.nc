
#include <lib6lowpan/ip.h>

interface UDP {
  /*
   * bind a local address.  to cut down memory requirements and handle the
   * common case well, you can only bind a port; all local interfaces are
   * implicitly bound.  the port should be passed in host byte-order (is 
   * this confusing?  
   */       

  command error_t bind(uint16_t port);

  /*
   * send a payload to the socket address indicated
   * once the call returns, the stack has no claim on the buffer pointed to
   */ 
  command error_t sendto(struct sockaddr_in6 *dest, void *payload, 
                         uint16_t len);

  command error_t sendtov(struct sockaddr_in6 *dest, 
                          struct ip_iovec *iov);

  /*
   * indicate that the stack has finished writing data into the
   * receive buffer.  if error is not SUCCESS, the payload does not
   * contain valid data and the src pointer should not be used.
   */
  event void recvfrom(struct sockaddr_in6 *src, void *payload, 
                      uint16_t len, struct ip6_metadata *meta);

}
