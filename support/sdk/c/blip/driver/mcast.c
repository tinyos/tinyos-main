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
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include <net/if.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>

#include "mcast.h"
#include "logging.h"

int __mcast_sock;
struct sockaddr_in6 __mcast_addr;
char __mcast_dev[IFNAMSIZ];

static int open_loopback(struct sockaddr_in6 *laddr) {

  /* we need to send to the loopback address, not the group  */
  memcpy(&__mcast_addr.sin6_addr, &in6addr_loopback, sizeof(struct in6_addr));
  memcpy(&laddr->sin6_addr, &in6addr_loopback, sizeof(struct in6_addr));

  /* bind to the local address (we're already BINDTODEVICE, so this
     might be redundant)  */
  if (bind(__mcast_sock, (struct sockaddr *)laddr, sizeof(struct sockaddr_in6)) < 0) {
    log_fatal_perror("binding multicast socket failed");
    goto fail;
  }

  return __mcast_sock;
 fail:
  close(__mcast_sock);
  return -1;
}

int mcast_start(char *dev) {
  struct ipv6_mreq join;
  struct ifreq ifr;
  int opt;
  int ifindex = if_nametoindex(dev);

  __mcast_addr.sin6_family = AF_INET6;
  inet_pton(AF_INET6, "ff12::cafe:babe", &__mcast_addr.sin6_addr);
  __mcast_addr.sin6_port = htons(10023);
  __mcast_addr.sin6_scope_id = ifindex;

  strncpy(__mcast_dev, dev, IFNAMSIZ);

  struct sockaddr_in6 laddr = {
    .sin6_family = AF_INET6,
    .sin6_port = __mcast_addr.sin6_port,
    .sin6_addr = IN6ADDR_ANY_INIT,
    .sin6_scope_id = ifindex,
  };


  /* get the socket */
  if ((__mcast_sock = socket(PF_INET6, SOCK_DGRAM, 0)) < 0) {
    log_fatal_perror("error opening socket");
    return -1;
  }

  /* bind it to the device we're going to join the link-local
     multicast group on */
  memset(&ifr, 0, sizeof(struct ifreq));
  strncpy(ifr.ifr_name, dev, IFNAMSIZ);
  if (setsockopt(__mcast_sock, SOL_SOCKET, SO_BINDTODEVICE,
                 (char *)&ifr, sizeof(struct ifreq)) < 0) {
    log_fatal_perror("could not BINDTODEVICE");
    goto fail;
  }

  /* the loopback on linux doesn't support multicast. that's okay,
     though, since we can just attach to it and use it to feed routing
     reports back into us.  */
  if (strncmp(dev, "lo", 2) == 0) {
    return open_loopback(&laddr);
  }

  /* receive messages we send */
  opt = 1;
  if (setsockopt(__mcast_sock, IPPROTO_IPV6, IPV6_MULTICAST_LOOP, &opt, sizeof(opt)) < 0) {
    log_fatal_perror("setting loop failed");
    goto fail;
  }

  opt = 1;
  if (setsockopt(__mcast_sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
    log_fatal_perror("setting reuse failed");
    goto fail;
  }

  /* bind to the local address (we're already BINDTODEVICE, so this
     might be redundant)  */
  if (bind(__mcast_sock, (struct sockaddr *)&laddr, sizeof(struct sockaddr_in6)) < 0) {
    log_fatal_perror("binding multicast socket failed");
    goto fail;
  }

  memset(&join, 0, sizeof(struct ipv6_mreq));
  memcpy(&join.ipv6mr_multiaddr, &__mcast_addr.sin6_addr, sizeof(struct in6_addr));
  join.ipv6mr_interface = ifindex;

  if (setsockopt(__mcast_sock, IPPROTO_IPV6, IPV6_ADD_MEMBERSHIP, &join, sizeof(join)) < 0) {
    log_fatal_perror("error joining group");
    goto fail;
  }

  return __mcast_sock;
 fail:
  close(__mcast_sock);
  return -1;
}



int mcast_recvfrom(struct sockaddr_in6 *from, void *buf, int len) {
  int rc;
  socklen_t fromlen = sizeof(struct sockaddr_in6);

  if ((rc = recvfrom(__mcast_sock, buf, len, 0, (struct sockaddr *)from, &fromlen)) < 0) { 
    log_fatal_perror("multicast receive");
    return -1;
  }
  return rc;
}

int mcast_send(void *data, int len) {
  int rc;

  if ((rc = sendto(__mcast_sock, data, len, 0, (struct sockaddr *)&__mcast_addr, sizeof(struct sockaddr_in6))) < 0) {
    log_fatal_perror("send failed");
    return -1;
  }
  return 0;
}

#if 0
int main(int argc, char **argv) {

  char *dev = argv[1];
  int fd;
  struct sockaddr_in6 grp = {
    .sin6_port = htons(10620),
  };

  if (argc < 2) {
    printf("\n\t%s <iface>\n\n", argv[0]);
    exit(1);
  }

  inet_pton(AF_INET6, "ff12::1abc", &grp.sin6_addr);

  fd = mcast_start(&grp, dev);
  printf("mcast start done: %i\n", fd);

  struct sockaddr_in6 from;
  char rxbuf[1024];
  int len;

  if (argc == 3 && strcmp(argv[2], "listen") == 0) {

    printf("listening\n");

    while (1) {
      len = mcast_recvfrom(&from, rxbuf, 1024);
      if (len > 0) {
        rxbuf[len] = '\0';
        puts(rxbuf);
      }
    }
  } else {
    char *msg = "hello, mcast world!";
    while (1) {
      mcast_send(msg, strlen(msg)+1);
      sleep(1);
      len = mcast_recvfrom(&from, rxbuf, 1024);
      if (len > 0) {
        rxbuf[len] = '\0';
        puts(rxbuf);
      }
      
    }
  }
}
#endif
