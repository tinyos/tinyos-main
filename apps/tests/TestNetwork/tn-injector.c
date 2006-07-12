#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sfsource.h"
#include "serialpacket.h"
#include "test_network_msg.h"
#include "set_rate_msg.h"
#include "TestNetworkC.h"

int main(int argc, char **argv)
{
  int fd,i;

  if (argc != 5) {
    fprintf(stderr, "Usage: %s <host> <port> <seqno> <rate> - change sample rate (ms/sample)\n", argv[0]);
    exit(2);
  }
  
  fd = open_sf_source(argv[1], atoi(argv[2]));

  if (fd < 0) {
    fprintf(stderr, "Couldn't open serial forwarder at %s:%s\n",
	    argv[1], argv[2]);
    exit(1);
  }
  uint8_t len = DISSEMINATION_MESSAGE_SIZE + SPACKET_SIZE + sizeof(uint16_t);
  void* storage = malloc(len);
  tmsg_t* serialMsg = new_tmsg(storage, len);
  void* payload = storage + (spacket_data_offsetbits(0) / 8);
  tmsg_t* dataMsg = new_tmsg(payload, DISSEMINATION_MESSAGE_SIZE + sizeof(uint16_t));
  void* data = payload + (dissemination_message_data_offsetbits(0) / 8);
  
  spacket_header_type_set(serialMsg, DISSEMINATION_MESSAGE_AM_TYPE);
  spacket_header_length_set(serialMsg, DISSEMINATION_MESSAGE_SIZE + sizeof(uint16_t));
  dissemination_message_key_set(dataMsg, SAMPLE_RATE_KEY);
  dissemination_message_seqno_set(dataMsg, atoi(argv[3]));

  uint16_t* rate = (uint16_t*)data;
  *rate = (uint16_t)atoi(argv[4]);

  printf("Writing packet:\n  ");
  for (i = 0; i < len; i++) {
    printf("%0.2x ", ((uint8_t*)storage)[i]);
  }
  printf("\n");
  write_sf_packet(fd,storage,len);
}
