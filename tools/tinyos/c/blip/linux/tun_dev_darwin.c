/*
 * "Copyright (c) 2008 The Regents of the University  of California.
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
 *
 * @author Stephen Dawson-Haggerty <stevedh@eecs.berkeley.edu>
 */

/* We're in macland here so we can do all the OSX-specific includes here  */

#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/in_var.h>
#include <arpa/inet.h>
#include <sys/sockio.h>

#include <lib6lowpan/lib6lowpan.h>
#include "tun_ioctls_darwin.h" 
#include "tun_dev.h"
#include "logging.h"

#if 0
int main(int argc, char **argv) {
  char devname[IFNAMSIZ];
  struct in6_addr addr;

  inet_pton(AF_INET6, "fec0::1", &addr);

  if (tun_open(devname) < 0) {
    exit(1);
  }

  if (tun_setup(devname, &addr, 128) < 0) {
    exit(1);
  }

  sleep(10);
}
#endif

int tun_open(char *dev) {
    int fd;
    int yes = 1;

    if ((fd = open("/dev/tun0", O_RDWR | O_NONBLOCK)) < 0)
      return -1;

    strncpy(dev, "tun0", IFNAMSIZ);

    /* this makes it so we have to prepend the address family to
       packets we write. */
    if (ioctl(fd, TUNSIFHEAD, &yes) < 0)
      goto failed;

    if (fcntl(fd, F_SETFL, O_NONBLOCK) < 0)
      goto failed;


    return fd;
  failed:
    log_fatal_perror("tun_open");
    close(fd);
    return -1;
}

int tun_setup(char *dev, struct in6_addr *addr, int pfxlen) {
  char addr_buf[256], cmd_buf[1024];
  struct in6_addr my_addr;
  struct ifreq ifr;
  int fd;
  pfxlen = 64;

  if ((fd = socket(PF_INET6, SOCK_DGRAM, 0)) < 0)
    return -1;

  memset(&ifr, 0, sizeof(struct ifreq));
  strncpy(ifr.ifr_name, dev, IFNAMSIZ);

  /* set the interface up */
  if (ioctl(fd, SIOCGIFFLAGS, &ifr) < 0) {
    log_fatal_perror("SIOCGIFFLAGS");
    return -1;
  }

  ifr.ifr_flags |= IFF_UP;
  if (ioctl(fd, SIOCSIFFLAGS, &ifr) < 0) {
    log_fatal_perror("SIOCSIFFLAGS");
    return -1;
  }
  /* MTU */
  ifr.ifr_mtu = 1280;
  if (ioctl(fd, SIOCSIFMTU, &ifr) < 0) {
    log_fatal_perror("SIOCSIFMTU");
    return -1;
  }
  /* Global address */
  memcpy(&my_addr, addr, sizeof(struct in6_addr));
  inet_ntop(AF_INET6, &my_addr, addr_buf, 256);
  snprintf(cmd_buf, 1024, "ifconfig %s inet6 %s/%i", dev, addr_buf, pfxlen);
  if (system(cmd_buf) != 0) {
    fatal("could not set global address!\n");
    return -1;
  }

  snprintf(cmd_buf, 1024, "route -q add -inet6 %s -prefixlen %i -interface %s > /dev/null", 
           addr_buf, pfxlen, dev);
  if (system(cmd_buf) != 0) {
    fatal("could not add route!\n");
    return -1;
  }

  snprintf(cmd_buf, 1024, "route -q add -inet6 fe80::%%%s -prefixlen %i -interface %s > /dev/null", 
           dev, 64, dev);
  if (system(cmd_buf) != 0) {
    fatal("could not LL add route!\n");
    return -1;
  }
  
  my_addr.__u6_addr.__u6_addr16[0] = htons(0xfe80);
  inet_ntop(AF_INET6, &my_addr, addr_buf, 256);
  snprintf(cmd_buf, 1024, "ifconfig %s inet6 %s/64", dev, addr_buf);
  if (system(cmd_buf) != 0) {
    fatal("could not set local address!\n");
    return -1;
  }

  return 0;
}

int tun_close(int fd, char *dev)
{
    return close(fd);
}

/* Read/write frames from TUN device */
int tun_write(int fd, struct split_ip_msg *msg)
{
  uint8_t buf[INET_MTU + sizeof(struct tun_pi)], *packet;
  struct tun_pi *pi = (struct tun_pi *)buf;
  struct generic_header *cur;
  packet = (uint8_t *)(pi + 1);


  if (ntohs(msg->hdr.plen) + sizeof(struct ip6_hdr) >= INET_MTU)
    return 1;

  pi->af = htonl(AF_INET6);

  memcpy(packet, &msg->hdr, sizeof(struct ip6_hdr));
  packet += sizeof(struct ip6_hdr);

  cur = msg->headers;
  while (cur != NULL) {
    memcpy(packet, cur->hdr.data, cur->len);
    packet += cur->len;
    cur = cur->next;
  }

  memcpy(packet, msg->data, msg->data_len);

  return write(fd, buf, sizeof(struct tun_pi) + sizeof(struct ip6_hdr) + ntohs(msg->hdr.plen));
}

int tun_read(int fd, char *buf, int len)
{
  int out;
  out = read(fd, buf, sizeof(struct tun_pi) + len);

  return out - sizeof(struct tun_pi);
}
