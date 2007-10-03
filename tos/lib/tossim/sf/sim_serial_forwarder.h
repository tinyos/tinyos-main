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

#ifndef  _SIM_SERIAL_FORWARDER_H_
#define  _SIM_SERIAL_FORWARDER_H_
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

struct sim_sf_client_list
{
    struct sim_sf_client_list *next;
    int fd;
};

void sim_sf_forward_packet(const void *packet, int len);
void sim_sf_dispatch_packet(const void *packet, int len);
void sim_sf_open_server_socket(int port);
void sim_sf_process ();

int sim_sf_unix_check(const char *msg, int result);
void *sim_sf_xmalloc(size_t s);
void sim_sf_fd_wait(fd_set *fds, int *maxfd, int fd);
void sim_sf_pstatus(void);
void sim_sf_add_client(int fd);
void sim_sf_rem_client(struct sim_sf_client_list **c);
void sim_sf_new_client(int fd);
void sim_sf_check_clients(fd_set *fds);
void sim_sf_wait_clients(fd_set *fds, int *maxfd);
void sim_sf_check_new_client(void);
void sim_sf_forward_packet(const void *packet, int len);
int sim_sf_saferead(int fd, void *buffer, int count);
int sim_sf_safewrite(int fd, const void *buffer, int count);
int sim_sf_open_source(const char *host, int port);
int sim_sf_init_source(int fd);
void *sim_sf_read_packet(int fd, int *len);
int sim_sf_write_packet(int fd, const void *packet, int len);

#ifdef __cplusplus
}
#endif

#endif   // ----- #ifndef _SIM_SERIAL_FORWARDER_H_  ----- 
