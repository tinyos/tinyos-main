#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sfsource.h"

void send_packet(int fd, char **bytes, int count)
{
  int i;
  unsigned char *packet;

  packet = malloc(count);
  if (!packet)
    exit(2);

  for (i = 0; i < count; i++)
    packet[i] = strtol(bytes[i], NULL, 0);
      
  fprintf(stderr,"Sending ");
  for (i = 0; i < count; i++)
    fprintf(stderr, " %02x", packet[i]);
  fprintf(stderr, "\n");

  write_sf_packet(fd, packet, count);
}

int main(int argc, char **argv)
{
  int fd;

  if (argc < 4)
    {
      fprintf(stderr, "Usage: %s <host> <port> <bytes> - send a raw packet to a serial forwarder\n", argv[0]);
      exit(2);
    }
  fd = open_sf_source(argv[1], atoi(argv[2]));
  if (fd < 0)
    {
      fprintf(stderr, "Couldn't open serial forwarder at %s:%s\n",
	      argv[1], argv[2]);
      exit(1);
    }

  send_packet(fd, argv + 3, argc - 3);

  close(fd);
}
