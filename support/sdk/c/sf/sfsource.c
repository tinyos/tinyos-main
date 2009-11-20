#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "sfsource.h"

int saferead(int fd, void *buffer, int count)
{
  int actual = 0;

  while (count > 0)
    {
      int n = read(fd, buffer, count);

      if (n == -1 && errno == EINTR)
	continue;
      if (n == -1)
	return -1;
      if (n == 0)
	return actual;

      count -= n;
      actual += n;
      buffer = (char*)buffer + n;
    }
  return actual;
}

int safewrite(int fd, const void *buffer, int count)
{
  int actual = 0;

  while (count > 0)
    {
      int n = write(fd, buffer, count);

      if (n == -1 && errno == EINTR)
	continue;
      if (n == -1)
	return -1;

      count -= n;
      actual += n;
      buffer = (char*)buffer + n;
    }
  return actual;
}

int open_sf_source(const char *host, int port)
/* Returns: file descriptor for serial forwarder at host:port
 */
{
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  struct hostent *entry;
  struct sockaddr_in addr;

  if (fd < 0)
    return fd;

  entry = gethostbyname(host);
  if (!entry)
    {
      close(fd);
      return -1;
    }      

  addr.sin_family = entry->h_addrtype;
  memcpy(&addr.sin_addr, entry->h_addr_list[0], entry->h_length);
  addr.sin_port = htons(port);
  if (connect(fd, (struct sockaddr *)&addr, sizeof addr) < 0)
    {
      close(fd);
      return -1;
    }

  if (init_sf_source(fd) < 0)
    {
      close(fd);
      return -1;
    }

  return fd;
}

int init_sf_source(int fd)
/* Effects: Checks that fd is following the TinyOS 2.0 serial forwarder 
     protocol. Use this if you obtain your file descriptor from some other
     source than open_sf_source (e.g., you're a server)
   Returns: 0 if it is, -1 otherwise
 */
{
  char check[2], us[2];
  int version;

  /* Indicate version and check if a TinyOS 2.0 serial forwarder on the
     other end */
  us[0] = 'U'; us[1] = ' ';
  if (safewrite(fd, us, 2) != 2 ||
      saferead(fd, check, 2) != 2 ||
      check[0] != 'U')
    return -1;

  version = check[1];
  if (us[1] < version)
    version = us[1];

  /* Add other cases here for later protocol versions */
  switch (version)
    {
    case ' ': break;
    default: return -1; /* not a valid version */
    }

  return 0;
}

void *read_sf_packet(int fd, int *len)
/* Effects: reads packet from serial forwarder on file descriptor fd
   Returns: the packet read (in newly allocated memory), and *len is
     set to the packet length, or NULL for failure
*/
{
  unsigned char l;
  void *packet;

  if (saferead(fd, &l, 1) != 1)
    return NULL;

  packet = malloc(l);
  if (!packet)
    return NULL;

  if (saferead(fd, packet, l) != l)
    {
      free(packet);
      return NULL;
    }
  *len = l;
  
  return packet;
}

int write_sf_packet(int fd, const void *packet, int len)
/* Effects: writes len byte packet to serial forwarder on file descriptor
     fd
   Returns: 0 if packet successfully written, -1 otherwise
*/
{
  unsigned char l = len;

  if (safewrite(fd, &l, 1) != 1 ||
      safewrite(fd, packet, l) != l)
    return -1;

  return 0;
}
