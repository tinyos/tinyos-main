#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
#include "bcl-1.2.0/src/lz.h"
#include "bcl-1.2.0/src/lz.c"

int main(int argc, char *argv[])
{  
  if (argc == 2) {
    FILE *fp = fopen(argv[1], "rb");
    
    if (fp == NULL) {
      fprintf(stderr, "ERROR: Can't open input file, %s!\n", argv[1]);
    } else {
      fseek(fp, 0, SEEK_END);
      {
        long size = ftell(fp);
        uint8_t in[size];
        uint8_t out[size];
        size_t in_size = 0;
        
        rewind(fp);
        in_size = fread(in, 1, size, fp);
        
        printf("%d\n", in_size);
        
        LZ_Uncompress(in, out, in_size);
        
        {
          int i = 0;
          for (i = 0; i < 96; i++) {
            printf("%d ", out[i]);
            if ((i + 1) % 12 == 0) {
              printf("\n");
            }
          }
        }
      }
    }
  } else {
    printf("Usage: %s\n <file name>", argv[0]);
  }

  return 0;
}
