#include <stdio.h>
#include <stdlib.h>

#include "serialsource.h"

static char *msgs[] = {
  "unknown_packet_type",
  "ack_timeout"	,
  "sync"	,
  "too_long"	,
  "too_short"	,
  "bad_sync"	,
  "bad_crc"	,
  "closed"	,
  "no_memory"	,
  "unix_error"
};

void stderr_msg(serial_source_msg problem)
{
  fprintf(stderr, "Note: %s\n", msgs[problem]);
}

void send_packet(serial_source src, char **bytes, int count)
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

  if (write_serial_packet(src, packet, count) == 0)
    printf("ack\n");
  else
    printf("noack\n");
}

int main(int argc, char **argv)
{
  serial_source src;

  if (argc < 3)
    {
      fprintf(stderr, "Usage: %s <device> <rate> <bytes> - send a raw packet to a serial port\n", argv[0]);
      exit(2);
    }
  src = open_serial_source(argv[1], platform_baud_rate(argv[2]), 0, stderr_msg);
  if (!src)
    {
      fprintf(stderr, "Couldn't open serial port at %s:%s\n",
	      argv[1], argv[2]);
      exit(1);
    }

  send_packet(src, argv + 3, argc - 3);
}
