#include <stdio.h>
#include <stdlib.h>

#include "sfsource.h"

int main(int argc, char **argv)
{
  int fd;

  if (argc != 3)
    {
      fprintf(stderr, "Usage: %s <host> <port> - dump packets from a serial forwarder\n", argv[0]);
      exit(2);
    }
  fd = open_sf_source(argv[1], atoi(argv[2]));
  if (fd < 0)
    {
      fprintf(stderr, "Couldn't open serial forwarder at %s:%s\n",
	      argv[1], argv[2]);
      exit(1);
    }
  for (;;)
    {
      int len, i;
      const unsigned char *packet = read_sf_packet(fd, &len);

      if (!packet)
	exit(0);
      for (i = 0; i < len; i++)
	printf("%02x ", packet[i]);
      putchar('\n');
      fflush(stdout);
      free((void *)packet);
    }
}
