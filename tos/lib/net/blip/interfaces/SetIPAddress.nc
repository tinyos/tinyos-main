
/**
 * Splitting the setAddress function into its own interface allows us to use
 * the wiring check to make sure that some module is setting the local node's
 * address. This is useful because there are many modules that set the node's
 * address upon boot including:
 *  - StaticIPAddressTosIdC
 *  - StaticIPAddressC
 *  - Dhcp6C
 *
 * It is up to the application to choose which addressing scheme it would
 * like to use.
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

#include <lib6lowpan/6lowpan.h>

interface SetIPAddress {
  command error_t setAddress(struct in6_addr *addr);
}
