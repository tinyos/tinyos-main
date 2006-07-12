#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sfsource.h"
#include "serialpacket.h"
#include "test_network_msg.h"
#include "collection_msg.h"
#include "set_rate_msg.h"
#include "TestNetworkC.h"

int main(int argc, char **argv)
{
  int fd,i;

  if (argc != 3) {
    fprintf(stderr, "Usage: %s <host> <port> - print received packets\n", argv[0]);
    exit(2);
  }
  
  fd = open_sf_source(argv[1], atoi(argv[2]));

  if (fd < 0) {
    fprintf(stderr, "Couldn't open serial forwarder at %s:%s\n",
	    argv[1], argv[2]);
    exit(1);
  }

  for (;;) {
    int len, i;
    const unsigned char *packet = read_sf_packet(fd, &len);
    char* myPacket = (char*)malloc(len);
    memcpy(myPacket, packet, len);
    free((void*)packet);
    
    if (!packet)
      exit(0);
    else {
      tmsg_t* serialMsg = new_tmsg(myPacket, len);
      void* payload = (void*)myPacket + (spacket_data_offsetbits(0) / 8);
      tmsg_t* dataMsg = new_tmsg(payload, len - SPACKET_SIZE);
      void* data = payload + (dissemination_message_data_offsetbits(0) / 8);
      
      
      for (i = 0; i < len; i++)
	printf("%02x ", packet[i]);
      putchar('\n');
      fflush(stdout);
      free((void *)myPacket);
    }
  }
}
