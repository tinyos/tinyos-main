
#include "ip.h"

uint8_t buf[128];

struct {
  char * astr;
  struct in6_addr addr;
} cases[] = {
  {"fe80::1",  {{0xfe, 0x80, 0,0,0,0,0,0,0,0,0,0,0,0,0,1}}},
  {"fe80:102:304:506:708:90a:b0c:d0e", {{0xfe, 0x80, 1,2,3,4,5,6,7,8,9,10,11,12,13,14}}},
};

struct in6_addr unpack_addr;

int main() {
  int tests = 0, failures = 0;
  int i;
  int write_len;
  struct in6_addr backwards;
  for (i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
    write_len = inet_ntop6(&cases[i].addr, buf, sizeof(buf));
    printf("%i %s\n", write_len, buf);

    tests++;
    if (strcmp(buf, cases[i].astr) != 0) {
      failures++;
    }

    /* round-trip test */
    tests++;
    inet_pton6(buf, &unpack_addr);
    if (memcmp(unpack_addr.s6_addr, cases[i].addr.s6_addr, 16)) {
      print_buffer(unpack_addr.s6_addr, 16);
      print_buffer(cases[i].addr.s6_addr, 16);
      failures++;
    }

    buf[5] = 0xde;
    buf[6] = 0xad;
    tests++;
    write_len = inet_ntop6(&cases[i].addr, buf, 5);
    if (write_len >= 5 || buf[5] != 0xde || buf[6] != 0xad) {
      printf("write len: %i %i\n", write_len, (write_len >= 5));
      print_buffer(buf, 10);
      failures ++;
    }



  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, (tests - failures), tests);
}
