
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"

int bit_range_zero_p(uint8_t *buf, int start, int end);

struct {
  int start;
  int end;
  int len;
  uint8_t data[32];
  int result;
} test_cases[] = {
  {0, 1, 1, {0x0}, 0},
  {0, 8, 1, {0x0}, 0},
  {0, 8, 1, {0x1}, -1},  
  {0, 1, 1, {0x1}, 0},  
  {0, 1, 1, {0xff}, -1},  
  {7, 8, 2, {0x1, 0x0}, -1},  
  {7, 15, 2, {0x1, 0x0}, -1},  
  {7, 15, 2, {0x0, 0x1}, 0},
  {7, 15, 2, {0x1, 0x1}, -1},
  {8, 24, 4, {0x1, 0x0, 0, 0x8}, 0},
  {8, 25, 4, {0x1, 0x0, 1, 0x8}, -1},
  {7, 25, 4, {0x1, 0x0, 0, 0x8}, -1},
  {8, 24, 4, {0xff, 0, 0, 0xff}, 0},
  {16, 120, 16, 
   {0xff, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01}, 0}
};

int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    int rc;

    rc = bit_range_zero_p(test_cases[i].data, test_cases[i].start, test_cases[i].end);
    printf("result: %i(%i)\n", rc, test_cases[i].result);
    if (rc == test_cases[i].result)
      success++;
    total++;

  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
