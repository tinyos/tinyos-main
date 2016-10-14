/*
 * Copyright (c) 2007 Toilers Research Group - Colorado School of Mines
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Toilers Research Group - Colorado School of
 *   Mines  nor the names of its contributors may be used to endorse
 *   or promote products derived from this software without specific
 *   prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * Author: Chad Metcalf
 * Date: July 9, 2007
 *
 * The serial forwarder for TOSSIM
 *
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>

#include "sim_serial_forwarder.h"
#include "sim_serial_packet.h"
#include "sim_tossim.h"

struct sim_sf_client_list *sim_sf_clients;
int sim_sf_server_socket;
int sim_sf_packets_read, sim_sf_packets_written, sim_sf_num_clients;

int sim_sf_unix_check(const char *msg, int result)
{
    if (result < 0)
    {
        perror(msg);
        exit(2);
    }

    return result;
}

void *sim_sf_xmalloc(size_t s)
{
    void *p = malloc(s);

    if (!p)
    {
        fprintf(stderr, "out of memory\n");
        exit(2);
    }
    return p;
}

void sim_sf_fd_wait(fd_set *fds, int *maxfd, int fd)
{
    if (fd > *maxfd)
        *maxfd = fd;
    FD_SET(fd, fds);
}

void sim_sf_pstatus(void)
{
    printf("clients %d, read %d, wrote %d\n", sim_sf_num_clients, sim_sf_packets_read,
           sim_sf_packets_written);
}

void sim_sf_add_client(int fd)
{
    struct sim_sf_client_list *c = (struct sim_sf_client_list*)sim_sf_xmalloc(sizeof *c);

    c->next = sim_sf_clients;
    sim_sf_clients = c;
    sim_sf_num_clients++;
    sim_sf_pstatus();

    c->fd = fd;
}

void sim_sf_rem_client(struct sim_sf_client_list **c)
{
    struct sim_sf_client_list *dead = *c;

    *c = dead->next;
    sim_sf_num_clients--;
    sim_sf_pstatus();
    close(dead->fd);
    free(dead);
}

void sim_sf_new_client(int fd)
{
    fcntl(fd, F_SETFL, 0);
    if (sim_sf_init_source(fd) < 0)
        close(fd);
    else
        sim_sf_add_client(fd);
}

void sim_sf_check_clients(fd_set *fds)
{
    struct sim_sf_client_list **c;

    for (c = &sim_sf_clients; *c; )
    {
        int isNext = 1;

        if (FD_ISSET((*c)->fd, fds))
        {
            int len;
            const void *packet = sim_sf_read_packet((*c)->fd, &len);

            if (packet)
            {
                sim_sf_forward_packet(packet, len);
                free((void *)packet);
            }
            else
            {
                sim_sf_rem_client(c);
                isNext = 0;
            }
        }
        if (isNext)
            c = &(*c)->next;
    }
}

void sim_sf_wait_clients(fd_set *fds, int *maxfd)
{
    struct sim_sf_client_list *c;

    for (c = sim_sf_clients; c; c = c->next)
        sim_sf_fd_wait(fds, maxfd, c->fd);
}

void sim_sf_dispatch_packet(const void *packet, int len)
{
    struct sim_sf_client_list **c;

    char* dispatchPacket = (char*) sim_sf_xmalloc(len+1);

    memset(dispatchPacket, 0, 1); // This is the dispatcher byte actually
    memcpy(dispatchPacket+1, (char*)packet+4, len);

    for (c = &sim_sf_clients; *c; )
        if (sim_sf_write_packet((*c)->fd, dispatchPacket, len+1) >= 0)
        {
            sim_sf_packets_written++;
            c = &(*c)->next;
        }
        else
            sim_sf_rem_client(c);

    free(dispatchPacket);
}

void sim_sf_open_server_socket(int port)
{
    struct sockaddr_in me;
    int opt;

    sim_sf_server_socket = sim_sf_unix_check("socket", socket(AF_INET, SOCK_STREAM, 0));
    sim_sf_unix_check("socket", fcntl(sim_sf_server_socket, F_SETFL, O_NONBLOCK));
    memset(&me, 0, sizeof me);
    me.sin_family = AF_INET;
    me.sin_port = htons(port);

    opt = 1;
    sim_sf_unix_check("setsockopt", setsockopt(sim_sf_server_socket, SOL_SOCKET, SO_REUSEADDR,
                                        (char *)&opt, sizeof(opt)));

    sim_sf_unix_check("bind", bind(sim_sf_server_socket, (struct sockaddr *)&me, sizeof me));
    sim_sf_unix_check("listen", listen(sim_sf_server_socket, 5));
}

void sim_sf_check_new_client(void)
{
    int clientfd = accept(sim_sf_server_socket, NULL, NULL);

    if (clientfd >= 0)
        sim_sf_new_client(clientfd);
}

void sim_sf_forward_packet(const void *packet, int len)
{
    uint16_t addr = sim_serial_packet_source((struct sim_serial_packet*)packet);
    //uint16_t addr = sim_serial_packet_destination((struct sim_serial_packet*)forwardPacket);
    char* forwardPacket = (char*)packet+4;

    printf("addr %04X\n", addr);

    sim_serial_packet_deliver(addr,
                             (struct sim_serial_packet*)forwardPacket,
                             sim_time());
    sim_sf_packets_read++;
}

void sim_sf_process ()
{

        fd_set rfds;
        int maxfd = -1;
        struct timeval zero;
        int ret;

        zero.tv_sec = zero.tv_usec = 0;

        FD_ZERO(&rfds);
        sim_sf_fd_wait(&rfds, &maxfd, sim_sf_server_socket);
        sim_sf_wait_clients(&rfds, &maxfd);

        ret = select(maxfd + 1, &rfds, NULL, NULL, &zero);
        if (ret >= 0)
        {
            if (FD_ISSET(sim_sf_server_socket, &rfds))
                sim_sf_check_new_client();

            sim_sf_check_clients(&rfds);
        }
}

int sim_sf_saferead(int fd, void *buffer, int count)
{
  int actual = 0;

  while (count > 0)
    {
      int n = read(fd, buffer, count);

      if (n == -1 && errno == EINTR)
        continue;
      if (n == -1)
        return -1;
      if (n == 0)
        return actual;

      count -= n;
      actual += n;
      buffer = (char*)buffer + n;
    }
  return actual;
}

int sim_sf_safewrite(int fd, const void *buffer, int count)
{
  int actual = 0;

  while (count > 0)
    {
      int n = write(fd, buffer, count);

      if (n == -1 && errno == EINTR)
        continue;
      if (n == -1)
        return -1;

      count -= n;
      actual += n;
      buffer = (char*)buffer + n;
    }
  return actual;
}

int sim_sf_open_source(const char *host, int port)
/* Returns: file descriptor for serial forwarder at host:port
 */
{
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  struct hostent *entry;
  struct sockaddr_in addr;

  if (fd < 0)
    return fd;

  entry = gethostbyname(host);
  if (!entry)
    {
      close(fd);
      return -1;
    }

  addr.sin_family = entry->h_addrtype;
  memcpy(&addr.sin_addr, entry->h_addr, entry->h_length);
  addr.sin_port = htons(port);
  if (connect(fd, (struct sockaddr *)&addr, sizeof addr) < 0)
    {
      close(fd);
      return -1;
    }

  if (sim_sf_init_source(fd) < 0)
    {
      close(fd);
      return -1;
    }

  return fd;
}

int sim_sf_init_source(int fd)
/* Effects: Checks that fd is following the TinyOS 2.0 serial forwarder
     protocol. Use this if you obtain your file descriptor from some other
     source than open_sf_source (e.g., you're a server)
   Returns: 0 if it is, -1 otherwise
 */
{
  char check[2], us[2];
  int version;

  /* Indicate version and check if a TinyOS 2.0 serial forwarder on the
     other end */
  us[0] = 'U'; us[1] = ' ';
  if (sim_sf_safewrite(fd, us, 2) != 2 ||
      sim_sf_saferead(fd, check, 2) != 2 ||
      check[0] != 'U')
    return -1;

  version = check[1];
  if (us[1] < version)
    version = us[1];

  /* Add other cases here for later protocol versions */
  switch (version)
    {
    case ' ': break;
    default: return -1; /* not a valid version */
    }

  return 0;
}

void *sim_sf_read_packet(int fd, int *len)
/* Effects: reads packet from serial forwarder on file descriptor fd
   Returns: the packet read (in newly allocated memory), and *len is
     set to the packet length, or NULL for failure
*/
{
  int i;
  unsigned char l;
  void *packet;

  if (sim_sf_saferead(fd, &l, 1) != 1)
    return NULL;

  packet = malloc(l+4);
  if (!packet)
    return NULL;

  if (sim_sf_saferead(fd, packet, 1) != 1)
  {
    free(packet);
    return NULL;
  }

  if (sim_sf_saferead(fd, &((char*)packet)[4], l-1) != l-1)
  {
    free(packet);
    return NULL;
  }

  //memcpy((char*)packet, (char*)packet+4, 4);

  *len = l-1+4;
  printf("packet l %d ", *len);
  for(i = 0; i<*len; i++) printf("%02X ", ((unsigned char*)packet)[i]);
  printf("\n");

  return packet;
}

int sim_sf_write_packet(int fd, const void *packet, int len)
/* Effects: writes len byte packet to serial forwarder on file descriptor
     fd
   Returns: 0 if packet successfully written, -1 otherwise
*/
{
  unsigned char l = len;

  if (sim_sf_safewrite(fd, &l, 1) != 1 ||
      sim_sf_safewrite(fd, packet, l) != l)
    return -1;

  return 0;
}

