/*
 * "Copyright (c) 2008, 2009 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

#include <stdio.h>
#include <string.h>
#include "circ.h"

/* void do_head_read(void *buf) { */
/*   char *read_data; */
/*   int i, data_len; */
/*   data_len = circ_buf_read_head(buf, (void **)&read_data); */
/*   printf("buf_read_head: %i\n", data_len); */
/*   for (i = 0; i < data_len; i++) */
/*     putc(((char *)read_data)[i], stdout); */
/*   putc('\n', stdout); */
/* } */

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
  memset(buf, 0, sizeof(buf));

  if (circ_buf_init(buf, 200, 0) < 0)
    printf("cir_buf_init: error\n");

  for (i=0;i<20;i++)
    data[i] = 'a' + i;

  if (circ_buf_write(buf, 0, data, 20) < 0)
    printf("circ_buf_write: error\n");

  circ_buf_dump(buf);

  if (circ_buf_write(buf, 10, data, 20) < 0)
    printf("circ_buf_write: error\n");

  circ_buf_dump(buf);


  if (circ_buf_write(buf, 50, data, 20) < 0)
    printf("circ_buf_write: error\n");

  // circ_buf_dump(buf);

  // do_head_read(buf);
  // circ_buf_dump(buf);

  if (circ_buf_write(buf, 30, data, 20) < 0)
    printf("circ_buf_write: error\n");

  // circ_buf_dump(buf);

  if (circ_buf_write(buf, 70, data, 20) < 0)
    printf("circ_buf_write: error\n");

  circ_buf_dump(buf);

  circ_shorten_head(buf, 10);
  circ_buf_dump(buf);

  memset(buf, 0, sizeof(buf));

  if (circ_buf_init(buf, 200, 0) < 0)
    printf("cir_buf_init: error\n");

  printf("\n\nRESTART\n\n");
  
  for (i = 0; i < 25; i++) {
    circ_buf_write(buf, i * 20, data, 20);
    do_read(buf, i * 20);
    circ_shorten_head(buf, (i > 0) ? (i - 1) * 20 : 0 * 10);
    circ_buf_dump(buf);
  }

  // do_read(buf, 50);

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
