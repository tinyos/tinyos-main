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
#ifndef NWSTATE_H
#define NWSTATE_H

#include <6lowpan.h>
/*
 * Defines a programatic representation of the link state of the network.
 * Also tracks observable statistics about the links present.
 *
 */

typedef uint16_t node_id_t;

struct route_path {
  uint16_t len;
  hw_addr_t path[0];
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
  struct path *next;
} path_t;

int nw_init();
int nw_add_incr_edge(node_id_t v1, struct topology_entry *v2);
void nw_report_node(node_id_t v);
path_t *nw_get_route(node_id_t v1, node_id_t v2);
void nw_free_path(path_t *path);
void nw_inval_node(node_id_t v);

void nw_unmark_links(node_id_t v);
void nw_clear_unmarked(node_id_t v);

int  nw_print_dotfile(char *filename);
void nw_print_routes();
void nw_print_links();
void nw_test_routes();

#endif
