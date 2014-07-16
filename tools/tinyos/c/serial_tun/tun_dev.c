/*
 * Copyright (c) 2007 Matus Harvan
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * The name of the author may not be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/if.h>
#include <linux/if_tun.h>
#include <linux/if_ether.h>

#include "tun_dev.h"


int tun_open(char *dev)
{
    struct ifreq ifr;
    int fd;

    if ((fd = open("/dev/net/tun", O_RDWR | O_NONBLOCK)) < 0)
       return -1;

    memset(&ifr, 0, sizeof(ifr));
    /* By default packets are tagged as IPv4. To tag them as IPv6,
     * thy need to be prefixed by struct tun_pi.
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
    close(fd);
    return -1;
}

int tun_close(int fd, char *dev)
{
    return close(fd);
}

/* Read/write frames from TUN device */
/*
int tun_write(int fd, char *buf, int len)
{
    return write(fd, buf, len);
}

int tun_read(int fd, char *buf, int len)
{
    return read(fd, buf, len);
}
*/
int tun_write(int fd, char *buf, int len)
{
    int out;
    struct tun_pi pi = {0, htons(ETH_P_IPV6)};
    char *nbuf = malloc(len+sizeof(struct tun_pi));
    if (!nbuf) {
	fprintf(stderr, "tun_write: out of memory!");
	return -1;
    }
    memcpy(nbuf, &pi, sizeof(struct tun_pi));
    memcpy(nbuf+sizeof(struct tun_pi), buf, len);
    out = write(fd, nbuf, len+sizeof(struct tun_pi));
    free(nbuf);
    return out;
}

int tun_read(int fd, char *buf, int len)
{
    int out;
    char *nbuf = malloc(len+sizeof(struct tun_pi));
    if (!nbuf) {
	fprintf(stderr, "tun_read: out of memory!");
	return -1;
    }
    out=read(fd, nbuf, len+sizeof(struct tun_pi));
    if (out > 0 && out >= sizeof(struct tun_pi)) {
	out-=sizeof(struct tun_pi);
	memcpy(buf, nbuf+sizeof(struct tun_pi), out);
	free(nbuf);
	return out;
    } else {
	free(nbuf);
	return -1;
    }
}
