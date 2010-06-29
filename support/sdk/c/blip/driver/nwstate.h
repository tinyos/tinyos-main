/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
#ifndef NWSTATE_H
#define NWSTATE_H

#include <lib6lowpan/6lowpan.h>
/*
 * Defines a programatic representation of the link state of the network.
 * Also tracks observable statistics about the links present.
 *
 */

enum {
  L_UNREPORTED,
  L_REPORTED,
  L_STICKY,
};

typedef uint16_t node_id_t;

struct route_path {
  uint16_t len;
  ieee154_saddr_t path[0];
};

typedef struct {
  node_id_t r1;
  node_id_t r2;
} link_key_t;

struct router;
struct link;

typedef struct link {
  struct router *n1;
  struct router *n2;

  struct link *next1;
  struct link *next2;

  int n1_reportcount;
  int n2_reportcount;

  int marked;

  float qual;
  int conf;
  int pc;
} link_t;

typedef node_id_t router_key_t;

typedef enum bool {
  FALSE,
  TRUE,
} bool_t;

typedef struct router {
  node_id_t id;
  link_t *links;
  struct router *next;

  int reports;
  int lastSeqno;
  struct timeval lastReport;

  bool_t isProxying;
  bool_t isController;

  

  // fields for shortest path
  // computation
  struct {
    // the current estimate of the 
    // distance to the source
    float dist;
    // the current prev pointer
    struct router *prev;
    // used for maintaining a list of
    // vertices we have not yet visited
    struct router *setptr;
  } sp;
} router_t;

typedef struct path {
  node_id_t node;
  int length;
  bool_t isController;
  struct path *next;
} path_t;

int nw_init();
link_t *nw_add_incr_edge(node_id_t v1, struct topology_entry *v2);
void nw_report_node(node_id_t v);
path_t *nw_get_route(node_id_t v1, node_id_t v2);
void nw_free_path(path_t *path);
void nw_inval_node(node_id_t v);
router_t *nw_get_router(node_id_t rid);
router_t *get_insert_router(node_id_t rid);
void nw_add_controller(node_id_t node);
void nw_remove_link(node_id_t n1, node_id_t n2);

void nw_unmark_links(node_id_t v);
void nw_clear_unmarked(node_id_t v);

int  nw_print_dotfile(char *filename);
void nw_print_routes(int fd, int argc, char **argv);
void nw_print_links(int fd, int argc, char **argv);
void nw_test_routes(int fd, int argc, char **argv);
void nw_add_sticky_edge(int fd, int argc, char **argv);
void nw_inval_node_sh(int fd, int argc, char **argv);

#endif
