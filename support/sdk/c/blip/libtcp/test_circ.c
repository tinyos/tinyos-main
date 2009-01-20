
#include <stdio.h>
#include "circ.h"

void do_head_read(void *buf) {
  char *read_data;
  int i, data_len;
  data_len = circ_buf_read_head(buf, (void **)&read_data);
  printf("buf_read_head: %i\n", data_len);
  for (i = 0; i < data_len; i++)
    putc(((char *)read_data)[i], stdout);
  putc('\n', stdout);
}

void do_read(void *buf, uint32_t sseqno) {
  char data[20];
  int data_len, i;
  data_len = circ_buf_read(buf, sseqno, data, 20);

  printf("buf_read: %i\n", data_len);
  for (i = 0; i < data_len; i++)
    putc(((char *)data)[i], stdout);
  putc('\n', stdout);

}

int main(int argc, char **argv) {
  char buf[200];
  char data[20], readbuf[30];
  int i = 20, data_len;
  char *read_data;
  if (circ_buf_init(buf, 200, 0, 1) < 0)
    printf("cir_buf_init: error\n");

  for (i=0;i<20;i++)
    data[i] = 'a' + i;

  if (circ_buf_write(buf, 0, data, 20) < 0)
    printf("circ_buf_write: error\n");

  if (circ_buf_write(buf, 10, data, 20) < 0)
    printf("circ_buf_write: error\n");


  if (circ_buf_write(buf, 50, data, 20) < 0)
    printf("circ_buf_write: error\n");

  circ_buf_dump(buf);

  do_head_read(buf);
  circ_buf_dump(buf);

  if (circ_buf_write(buf, 30, data, 20) < 0)
    printf("circ_buf_write: error\n");

  circ_buf_dump(buf);

  if (circ_buf_write(buf, 70, data, 20) < 0)
    printf("circ_buf_write: error\n");

  circ_buf_dump(buf);

  do_read(buf, 50);
/*   do_head_read(buf); */
/*   circ_buf_dump(buf); */

/*   if (circ_buf_write(buf, 90, data, 20) < 0) */
/*     printf("circ_buf_write: error\n"); */
/*   if (circ_buf_write(buf, 110, data, 20) < 0) */
/*     printf("circ_buf_write: error\n"); */
/*   if (circ_buf_write(buf, 130, data, 20) < 0) */
/*     printf("circ_buf_write: error\n"); */

/*   circ_buf_dump(buf); */
/*   do_head_read(buf); */
/*   do_head_read(buf); */
/*   circ_buf_dump(buf); */
}
