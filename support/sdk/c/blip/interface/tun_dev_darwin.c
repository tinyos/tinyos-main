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
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/in_var.h>
#include <arpa/inet.h>
#include <sys/sockio.h>

#include "lib6lowpan/lib6lowpan.h"
#include "lib6lowpan/blip-pc-includes.h"
#include "tun_ioctls_darwin.h" 
#include "tun_dev.h"
#include "logging.h"

int tun_open(char *dev) {
    int fd;
    int yes = 1, flags;

    if ((fd = open("/dev/tun0", O_RDWR)) < 0)
      return -1;

    if (dev) strncpy(dev, "tun0", IF_NAMESIZE);

    /* this makes it so we have to prepend the address family to
       packets we write. */
    if (ioctl(fd, TUNSIFHEAD, &yes) < 0)
      goto failed;

/*     if (fcntl(fd, F_SETFL, O_NONBLOCK) < 0) */
/*       goto failed; */

    /* for some reason it defaults to nonblocking...  */
    flags = fcntl(fd, F_GETFL, 0);
    flags &= ~O_NONBLOCK;
    fcntl(fd, F_SETFL, flags);

    return fd;
  failed:
    log_fatal_perror("tun_open");
    close(fd);
    return -1;
}

int tun_setup(char *dev, ieee154_laddr_t link_address) {
  char addr_buf[256], cmd_buf[1024];
  struct in6_addr my_addr;
  struct ifreq ifr;
  int fd;

  if ((fd = socket(PF_INET6, SOCK_DGRAM, 0)) < 0)
    return -1;

  memset(&ifr, 0, sizeof(struct ifreq));
  strncpy(ifr.ifr_name, dev, IF_NAMESIZE);

  /* set the interface up */
  if (ioctl(fd, SIOCGIFFLAGS, &ifr) < 0) {
    log_fatal_perror("SIOCGIFFLAGS");
    return -1;
  }

  ifr.ifr_flags |= IFF_UP | IFF_BROADCAST;
  ifr.ifr_flags &= ~IFF_POINTOPOINT;

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

  /* link-local address */
  memset(my_addr.s6_addr, 0, 16);
  my_addr.s6_addr[0] = 0xfe;
  my_addr.s6_addr[1] = 0x80;
  memcpy(&my_addr.s6_addr[8], link_address.data, 8);

  /* add address alias */
  inet_ntop(AF_INET6, &my_addr, addr_buf, 256);
  snprintf(cmd_buf, 1024, "ifconfig %s inet6 %s/64", dev, addr_buf);
  printf("%s\n", cmd_buf);
  if (system(cmd_buf) != 0) {
    fatal("could not set local address!\n");
    return -1;
  }

  /* remove any existing addresses */
  snprintf(cmd_buf, 1024, 
           "ifconfig %s inet6 `ifconfig %s | grep inet6 | cut -f2 | cut -f2 -d' ' | head -n1` -alias ",
           dev, dev);
  printf("%s\n", cmd_buf);
  if (system(cmd_buf) != 0) {
    
  }

  /* not exactly sure why the last command doesn't take effect right away...  */
  sleep(1);

  snprintf(cmd_buf, 1024, "route -q add -inet6 fe80::%%%s -prefixlen %i -interface %s > /dev/null",
           dev, 64, dev);
  printf("%s\n", cmd_buf);
  if (system(cmd_buf) != 0) {
    fatal("could not add route!\n");
    return -1;
  }
  

  /* Global address */
/*   memcpy(&my_addr, addr, sizeof(struct in6_addr)); */
/*   inet_ntop(AF_INET6, &my_addr, addr_buf, 256); */
/*   snprintf(cmd_buf, 1024, "ifconfig %s inet6 %s/%i", dev, addr_buf, pfxlen); */
/*   if (system(cmd_buf) != 0) { */
/*     fatal("could not set global address!\n"); */
/*     return -1; */
/*   } */

  
/*   my_addr.__u6_addr.__u6_addr16[0] = htons(0xfe80); */

  return 0;
}

int tun_close(int fd, char *dev)
{
    return close(fd);
}

/* Read/write frames from TUN device */
int tun_write(int fd, struct ip6_packet *msg) {
  uint8_t buf[INET_MTU + sizeof(struct tun_pi)], *packet;
  struct tun_pi *pi = (struct tun_pi *)buf;
  int length = sizeof(struct ip6_hdr) + sizeof(struct tun_pi);
  packet = (uint8_t *)(pi + 1);

  if (ntohs(msg->ip6_hdr.ip6_plen) + sizeof(struct ip6_hdr) >= INET_MTU)
    return 1;

  pi->af = htonl(AF_INET6);

  memcpy(packet, &msg->ip6_hdr, sizeof(struct ip6_hdr));
  packet += sizeof(struct ip6_hdr);
  length += iov_read(msg->ip6_data, 0, iov_len(msg->ip6_data), packet);
  
  debug("delivering packet\n");
  print_buffer(buf, length);

  return write(fd, buf, length);
}

int tun_read(int fd, char *buf, int len)
{
  int out;
  out = read(fd, buf, len);
  if (out < 0)
    log_fatal_perror("tun_read");

  return out;
}
