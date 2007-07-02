#ifndef SFSOURCE_H
#define SFSOURCE_H

#ifdef __cplusplus
extern "C" {
#endif

int open_sf_source(const char *host, int port);
/* Returns: file descriptor for TinyOS 2.0 serial forwarder at host:port, or
     -1 for failure
 */

int init_sf_source(int fd);
/* Effects: Checks that fd is following the TinyOS 2.0 serial forwarder 
     protocol. Use this if you obtain your file descriptor from some other
     source than open_sf_source (e.g., you're a server)
   Returns: 0 if it is, -1 otherwise
 */

void *read_sf_packet(int fd, int *len);
/* Effects: reads packet from serial forwarder on file descriptor fd
   Returns: the packet read (in newly allocated memory), and *len is
     set to the packet length
*/

int write_sf_packet(int fd, const void *packet, int len);
/* Effects: writes len byte packet to serial forwarder on file descriptor
     fd
   Returns: 0 if packet successfully written, -1 otherwise
*/

#ifdef __cplusplus
}
#endif

#endif
