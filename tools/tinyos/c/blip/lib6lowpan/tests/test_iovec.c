#include <stdint.h>
#include <string.h>
#ifdef UNIT_TESTING
#include <stdio.h>
#endif

#include "lib6lowpan.h"
#include "iovec.h"

/* test some different write patters testing overlap and boundary
   conditions */
struct test_case {
  int offset, len;
} test_cases[] = {
  {5, 5},
  {5, 10},
  {9, 1},
  {10, 1},
  {25, 10},
  {25, 25},
};

int main() {
  int total = 0, successes = 0;
  /* test 1:  */
    struct ip_iovec v[10];
    uint8_t buf[1500], orig[1500], zeroes[1500];
    int i;
    printf("starting spread write test\n");
    scribble(buf, sizeof(buf));
    memcpy(orig, buf, sizeof(buf));
    memset(zeroes, 0, sizeof(zeroes));
    for(i = 0; i < 10; i++) {
      v[i].iov_len = 10;
      v[i].iov_base = &buf[i*10];
      if (i < 9)
        v[i].iov_next = &v[i+1];
      else v[i].iov_next = NULL;
    }
    iov_print(v);

    for (i = 0; i < sizeof(test_cases) / sizeof(test_cases[0]); i++) {
      int rv;
      printf("iov_write: test %i offset: %i length: %i\n", i + 1, 
              test_cases[i].offset, test_cases[i].len);
      total++;
      rv = iov_update(v, test_cases[i].offset, test_cases[i].len, zeroes);
      if (rv = test_cases[i].len &&
          memcmp(buf, orig, test_cases[i].offset) == 0 && 
          memcmp(buf+test_cases[i].offset, zeroes+test_cases[i].offset, test_cases[i].len) == 0 &&
          memcmp(buf+test_cases[i].offset+test_cases[i].len, 
                 orig+test_cases[i].offset+test_cases[i].len, 100 - test_cases[i].offset -test_cases[i].len) == 0) {
        printf("test: success\n");
        successes ++;
      }
      iov_print(v);
      memcpy(buf, orig, sizeof(buf));
      printf("\n\n");
    }

  printf("%s: %i/%i tests succeeded\n", __FILE__, successes, total);
}
