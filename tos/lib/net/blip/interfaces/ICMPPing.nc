
#include <ICMP.h>

interface ICMPPing {

  command error_t ping(struct in6_addr *target, uint16_t period, uint16_t n);

  event void pingReply(struct in6_addr *source, struct icmp_stats *stats);

  event void pingDone(uint16_t ping_rcv, uint16_t ping_n);

}
