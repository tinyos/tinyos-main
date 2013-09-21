/*
 * Basic wrapper for instantiating the DHCP components to use to set the local
 * IP address.
 *
 * @author: Brad Campbell <bradjc@umich.edu>
 */

configuration Dhcp6C {
}
implementation {
  components Dhcp6RelayC;
  components Dhcp6ClientC;
}
