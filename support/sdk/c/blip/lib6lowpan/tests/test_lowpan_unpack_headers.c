


#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"
#include "iovec.h"

int     packet_len;
uint8_t packet[1280];

struct  {
  char *file;
} cases[] = {
  {"packet4.test"},
};

int parse_packet(char *file) {
  char buf[127], *pos = buf;
  uint8_t *packet_cur = packet;
  FILE *fp = fopen(file, "r");
  if (!fp) return -1;

  while (!feof(fp)) {
    while (!feof(fp) && isspace(*pos = fgetc(fp)));
    pos++;
    while (!feof(fp) && !isspace((*pos++ = fgetc(fp))));
    *(pos-1) = '\0';

    if (pos > buf + 1)
      *packet_cur++ = (uint8_t) strtol(buf, NULL, 16);

    pos = buf;
  }
  packet_len = (packet_cur - packet);
  return 0;
}

int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(cases) / sizeof(cases[0])); i++) {
    struct packed_lowmsg lowmsg;
    struct lowpan_reconstruct recon;
    struct ieee154_frame_addr frame_address;
    uint8_t *buf = packet, *frame = packet;
    int length;
    int rv;

    parse_packet(cases[i].file);
    length = packet_len;
    print_buffer(packet, packet_len);

    buf     = unpack_ieee154_hdr(buf, &frame_address);
    length -= buf - frame;

    lowmsg.data = buf;
    lowmsg.len  = length;
    lowmsg.headers = getHeaderBitmap(&lowmsg);
    if (lowmsg.headers == LOWMSG_NALP) {
      warn("lowmsg NALP!\n");
      continue;
    }

    buf = getLowpanPayload(&lowmsg);
    if ((rv = lowpan_recon_start(&frame_address, &recon, buf, length)) < 0) {
      warn("reconstruction failed!\n");
      continue;
    }

    if (recon.r_size == recon.r_bytes_rcvd) {
      printf("recon successful\n");
      print_buffer(recon.r_buf, recon.r_size);
    } else {
      free(recon.r_buf);
    }
    
  }

  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 0;
}

int main() {
  return run_tests();
}
