
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"
#include "internal.h"


struct {
  uint8_t  nxt_hdr;
  uint16_t unpacked_length;

  int pack_len;
  uint8_t pack[2];
  int data_length;
} test_cases[] = {
  {IPV6_HOP, 0, 1, {LOWPAN_NHC_IPV6_PATTERN | LOWPAN_NHC_EID_HOP | LOWPAN_NHC_NH}, 8},
  {IPV6_MOBILITY, 1, 1, {LOWPAN_NHC_IPV6_PATTERN | LOWPAN_NHC_EID_MOBILE | LOWPAN_NHC_NH}, 13},
  {IPV6_IPV6, 14, 1, {LOWPAN_NHC_IPV6_PATTERN | LOWPAN_NHC_EID_IPV6 | LOWPAN_NHC_NH}, 120},

  {IPV6_IPV6, 1, 2, {LOWPAN_NHC_IPV6_PATTERN | LOWPAN_NHC_EID_IPV6, IANA_UDP}, 12},
};


int run_tests() {
  int i, j;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    uint8_t nxt_hdr;
    uint8_t buf[512], result[512];
    uint8_t *rv, *pack;
    total++;

    memset(buf, 0, 512);        /* this fills in pad1 options for any weird sized options */
    memcpy(buf, test_cases[i].pack, test_cases[i].pack_len);
    pack = buf + test_cases[i].pack_len;

    *pack++ = test_cases[i].data_length;
    for (j = 12; j < 12 + test_cases[i].data_length - 2; j++)
      *pack++ = j;

    printf("INPUT: ");
    for (j = 0; j < test_cases[i].data_length; j++)
      printf("0x%x ", buf[j]);
    printf("\n");

    rv = unpack_ipnh(result, sizeof(result), &nxt_hdr, buf);

    printf("ip6_ext nxt: %i length: %i\n", nxt_hdr, result[1]);
    for (j = 0; j < (result[1] +1)*8; j++) {
      printf("0x%x ", result[j]);
    }
    printf("\n");

    // printf("%i:\n", test_cases[i].unpacked_length);
    if (test_cases[i].unpacked_length != result[1]) {
      printf("ERROR: wrong length: %i %i\n", test_cases[i].unpacked_length, result[1]);
      continue;
    }

    if (test_cases[i].nxt_hdr != nxt_hdr) {
      printf("ERROR: wrong next header: %i %i\n", test_cases[i].nxt_hdr, nxt_hdr);
      continue;
    }

    if (test_cases[i].pack_len == 2 && result[0] != test_cases[i].pack[1]) {
      printf("ERROR: wrong inline NH\n");
      continue;
    }

    for (j = 2; j < test_cases[i].data_length; j++) {
      if (result[j] != j + 10) {
        printf("ERROR: wrong payload\n");
        break;
      }
    }
    success++;
    printf("\n\n\n");
  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
