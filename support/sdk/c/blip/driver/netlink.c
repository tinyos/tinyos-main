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
#include <netinet/in.h>
#include <netinet/ip.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <arpa/inet.h>

#include "logging.h"

static int __nl_sock;
static int __if_index;

/* 
 * Start a netlink session.
 *
 */
int nl_init() {
  struct sockaddr_nl nladdr;

  /* with any luck, we've constructed the message, can send it to the
     kernel, and have a beer. */
  if ((__nl_sock = socket(PF_NETLINK, SOCK_RAW, NETLINK_ROUTE)) < 0) {
    log_fatal_perror("PACKETLINK socket");
    return -1;
  }

  memset(&nladdr, 0, sizeof(nladdr));
  nladdr.nl_family = AF_NETLINK;
  nladdr.nl_groups = 0;
  if (bind(__nl_sock, (struct sockaddr*)&nladdr, sizeof(nladdr)) < 0) {
    close(__nl_sock);
    log_fatal_perror("Cannot bind netlink socket");
    return -1;
  }
  return 0;
}

int nl_shutdown() {
  close(__nl_sock);
  __nl_sock = __if_index = -1;
  return 0;
}

/*
 * Start proxying addr on device 'dev'
 */
static int nl_cmd(int type, int flags, struct in6_addr *addr, char *dev) {
  static int seq;
  struct {
    struct nlmsghdr 	n;
    struct ndmsg 		ndm;
    char   			buf[256];
  } req;
  struct rtattr *rta;
  struct sockaddr_nl nladdr;

  memset(&req, 0, sizeof(req));
  
  /* set up our request packet with one request */
  req.n.nlmsg_len = NLMSG_LENGTH(sizeof(struct ndmsg));
  req.n.nlmsg_flags = NLM_F_REQUEST | flags; 
  req.n.nlmsg_type = type;
  req.ndm.ndm_family = AF_INET6;
  req.ndm.ndm_state = NUD_PERMANENT;
  req.ndm.ndm_ifindex = if_nametoindex(dev);

  /* add the actual address to the tail of the message  */
  int nl_len = RTA_LENGTH(sizeof(struct in6_addr));
  if (NLMSG_ALIGN(req.n.nlmsg_len) + RTA_ALIGN(nl_len) > sizeof(req)) {
    fprintf(stderr, "message too long\n");
    return -1;
  }

  rta = ((struct rtattr *) (((void *) (&req.n)) + NLMSG_ALIGN((req.n.nlmsg_len))));
  rta->rta_type = NDA_DST;
  rta->rta_len = nl_len;
  memcpy(RTA_DATA(rta), addr, sizeof(struct in6_addr));
  req.n.nlmsg_len = NLMSG_ALIGN(req.n.nlmsg_len) + RTA_ALIGN(nl_len);

  struct iovec iov = {
    .iov_base = (void*) &req.n,
    .iov_len = req.n.nlmsg_len
  };
  struct msghdr msg = {
    .msg_name = &nladdr,
    .msg_namelen = sizeof(nladdr),
    .msg_iov = &iov,
    .msg_iovlen = 1,
  };

  memset(&nladdr, 0, sizeof(nladdr));
  nladdr.nl_family = AF_NETLINK;
  req.n.nlmsg_seq = seq++;
  
  if (sendmsg(__nl_sock, &msg, 0) < 0) {
    log_fatal_perror("RTNETLINK");
    return -1;
  }
  /* TODO : nonblocking receive to check for error? */


  return 0;

  ///

  char buf[16384];

	iov.iov_base = buf;
	while (1) {
		int status;
		struct nlmsghdr *h;

		iov.iov_len = sizeof(buf);
		status = recvmsg(__nl_sock, &msg, 0);

		if (status < 0) {
			if (errno == EINTR)
				continue;
			log_fatal_perror("OVERRUN");
			continue;
		}

		if (status == 0) {
			fprintf(stderr, "EOF on netlink\n");
			return -1;
		}

		h = (struct nlmsghdr*)buf;
		while (NLMSG_OK(h, status)) {
			int err;

			if (nladdr.nl_pid != 0 ||
			    h->nlmsg_pid != 0 ||
			    h->nlmsg_seq != seq) {
					if (err < 0)
						return err;

				goto skip_it;
			}

			if (h->nlmsg_type == NLMSG_DONE)
				return 0;
			if (h->nlmsg_type == NLMSG_ERROR) {
				struct nlmsgerr *err = (struct nlmsgerr*)NLMSG_DATA(h);
				if (h->nlmsg_len < NLMSG_LENGTH(sizeof(struct nlmsgerr))) {
					fprintf(stderr, "ERROR truncated\n");
				} else {
					errno = -err->error;
					log_fatal_perror("RTNETLINK answers");
				}
				return -1;
			}
skip_it:
			h = NLMSG_NEXT(h, status);
		}
		if (msg.msg_flags & MSG_TRUNC) {
			fprintf(stderr, "Message truncated\n");
			continue;
		}
		if (status) {
			fprintf(stderr, "!!!Remnant of size %d\n", status);
			exit(1);
		}
	}
  return 0;
}

int nl_nd_add_neigh(struct in6_addr *addr, char *dev) {
  return nl_cmd(RTM_NEWNEIGH, NLM_F_CREATE|NLM_F_REPLACE, addr, dev);
}
int nl_nd_del_neigh(struct in6_addr *addr, char *dev) {
  return nl_cmd(RTM_DELNEIGH, 0, addr, dev);
}
int nl_nd_add_proxy(struct in6_addr *addr, char *dev) {
  // SDH : shit, the netlink proxy doesn't work (the add neighbor
  // did).  I WILL fix it... later.
  char buf [100], cmd[256];
  inet_ntop(AF_INET6, addr, buf, 100);
  snprintf(cmd, sizeof(cmd), "ip neigh add proxy %s dev %s\n", buf, dev);
  system(cmd);
  return 0;

  // return nl_cmd(RTM_NEWNEIGH, NLM_F_CREATE|NLM_F_EXCL|NTF_PROXY, addr, dev);
}
