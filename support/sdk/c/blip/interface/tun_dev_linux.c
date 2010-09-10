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
 */

#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/if_ether.h>

#include <netinet/in.h>
#include <lib6lowpan/lib6lowpan.h>

#include "tun_dev.h"
#include "logging.h"


/*
 *    This is in linux/include/net/ipv6.h.
 *    Thanks, net-tools!
 */
struct in6_ifreq {
    struct in6_addr ifr6_addr;
    __u32 ifr6_prefixlen;
    unsigned int ifr6_ifindex;
};


int tun_open(char *dev)
{
    struct ifreq ifr;
    int fd;

    if ((fd = open("/dev/net/tun", O_RDWR)) < 0)
	return -1;

    memset(&ifr, 0, sizeof(ifr));
    /* By default packets are tagged as IPv4. To tag them as IPv6,
     * they need to be prefixed by struct tun_pi.
     */
    //ifr.ifr_flags = IFF_TUN | IFF_NO_PI;
    ifr.ifr_flags = IFF_TUN;
    if (*dev)
	strncpy(ifr.ifr_name, dev, IFNAMSIZ);

    if (ioctl(fd, TUNSETIFF, (void *) &ifr) < 0)
	goto failed;

    strcpy(dev, ifr.ifr_name);
    return fd;

  failed:
    log_fatal_perror("tun_open");
    close(fd);
    return -1;
}

int tun_setup(char *dev, ieee154_laddr_t link_address) {
  struct in6_ifreq ifr6;
  struct ifreq ifr;
  int fd;

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

  /* Addresses */
  memset(&ifr6, 0, sizeof(struct in6_ifreq));
  // memcpy(&ifr6.ifr6_addr, addr, 16);
  if (ioctl(fd, SIOGIFINDEX, &ifr) < 0) {
    log_fatal_perror("SIOGIFINDEX");
    return -1;
  }

  ifr6.ifr6_ifindex = ifr.ifr_ifindex;
  /* don't set the global address */
/*   ifr6.ifr6_prefixlen = pfxlen; */
/*   if (ioctl(fd, SIOCSIFADDR, &ifr6) < 0) { */
/*     log_fatal_perror("SIOCSIFADDR (global)"); */
/*     return -1; */
/*   } */

  /* Just set the lin-local... */
  ifr6.ifr6_addr.s6_addr16[0] = htons(0xfe80);
  ifr6.ifr6_prefixlen = 64;
  memcpy(&ifr6.ifr6_addr.s6_addr[8], link_address.data, 8);
  
  if (ioctl(fd, SIOCSIFADDR, &ifr6) < 0) {
    log_fatal_perror("SIOCSIFADDR (local)");
    return -1;
  }

  close(fd);

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

  pi->flags = 0;
  pi->proto = htons(ETH_P_IPV6);

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
  out = read(fd, buf, sizeof(struct tun_pi) + len);

  return out;
}
