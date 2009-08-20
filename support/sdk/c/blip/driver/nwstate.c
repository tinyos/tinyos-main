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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <float.h>
#include <time.h>
#include <sys/time.h>
#include "lib6lowpan/lib6lowpan.h"

#include "nwstate.h"
#include "hashtable.h"
#include "logging.h"
#include "routing.h"
#include "vty/vty.h"

struct hashtable *links;
struct hashtable *routers;

router_t *router_list = NULL;
int routes_out_of_date = 1;

extern struct in6_addr __my_address;


void compute_routes(node_id_t v1);
//
// general boilerplate
// 

static unsigned int hash_link(void *k) {
  link_key_t *l = (link_key_t *)k;
  if (l->r1 > l->r2)
    return (l->r1 | (l->r2 << 16));
  else
    return (l->r2 | (l->r1 << 16));
}
static int link_equal(void *k1, void *k2) {
  link_key_t *l1 = (link_key_t *)k1;
  link_key_t *l2 = (link_key_t *)k2;
  return ((l1->r1 == l2->r1 && l1->r2 == l2->r2) ||
          (l1->r1 == l2->r2 && l1->r2 == l2->r1));
}

static unsigned int hash_router(void *k) {
  return *((router_key_t *)k);
}

static int router_equal(void *k1, void *k2) {
  return ((router_t *)k1)->id == ((router_t *)k2)->id;
}

int do_print = 0;
int do_routes = 0;
int printCount = 0;

int nw_print_dotfile(char *filename) {
  router_t *r;
  link_t *e;
  FILE *fp = fopen (filename, "w");
  if (fp == NULL) return -1;
  info("writing topology to '%s'\n", filename);
  printCount ++;
  fprintf(fp, "digraph Network {\n");
  
  for (r = router_list; r != NULL; r = r->next) {
    for (e = r->links; e != NULL; e = e->next1) {
      if (e->pc < printCount) {
        fprintf(fp, "  \"0x%x\" -> \"0x%x\" [label=\"%f\"]\n", e->n1->id, e->n2->id, e->qual);
        e->pc = printCount;
      }
    }
    for (e = r->links; e != NULL; e = e->next2) {
      if (e->pc < printCount) {
        fprintf(fp, "  \"0x%x\" -> \"0x%x\" [label=\"%f\"]\n", e->n1->id, e->n2->id, e->qual);
        e->pc = printCount;
      }
    }
  }

  fprintf(fp, "}\n");
  fclose(fp);
  return 0;
}


void nw_print_routes(int fd, int argc, char **argv) {
  VTY_HEAD;
  router_t *r,*s;
  for (r = router_list; r != NULL; r = r->next) {
    VTY_printf("  0x%x: ", r->id);
    for (s = r->sp.prev; s != NULL; s = s->sp.prev) {
      VTY_printf("0x%x", s->id);
      if (r->isController) VTY_printf("[C] ");
      else VTY_printf(" ");
    }
    VTY_printf("\r\n");
    VTY_flush();
  }
}

void nw_test_routes(int fd, int argc, char **argv) {
  node_id_t dest = ntohs(__my_address.s6_addr16[7]);
  debug("nwstate: computing new routes (root: 0x%x)\n", ntohs(__my_address.s6_addr16[7]));
  compute_routes(dest);
}

void nw_print_links(int fd, int argc, char **argv) {
  VTY_HEAD;
  struct tm *ltime;
  int target = -1;
  router_t *r;
  link_t *l;

  if (argc == 2)
    target = atoi(argv[1]);

  for (r = router_list; r != NULL; r = r->next) {
    char flags[16]; int pos = 0;
    if (target >= 0 && r->id != target) continue;

    flags[0] = '\0';
    if (r->isProxying || r->isController) {
      flags[pos++] = '['; 
      if (r->isController) flags[pos++] = 'C';
      if (r->isProxying) flags[pos++] = 'P';
      flags[pos++] = ']';
      flags[pos++] = '\0';
    }

    VTY_printf(" 0x%x%s: dist: ", r->id, flags);
    if (r->sp.dist == FLT_MAX)
      VTY_printf("Inf");
    else
      VTY_printf("%.1f", r->sp.dist);
    if (!r->isController) {
      ltime = localtime(&r->lastReport.tv_sec);
      VTY_printf(" reported: " ISO8601_FMT(ltime, &r->lastReport));
    }

    VTY_printf("\r\n");
    for (l = r->links; l != NULL; l = (r == l->n1) ? l->next1 : l->next2) {
      if (r == l->n1) {
        VTY_printf("  --> 0x%x [%.1f]\r\n", l->n2->id, l->qual);
      }
    }
    VTY_printf("\r\n");
    VTY_flush();
  }
}

void nw_add_sticky_edge(int fd, int argc, char **argv) {
  VTY_HEAD;
  int v1, v2;
  if (argc == 3) {
    link_t *l;
    struct topology_entry te;
    v1 = atoi(argv[1]);
    v2 = atoi(argv[2]);
    VTY_printf("adding sticky edge between %i and %i\r\n", v1, v2);
    te.etx = 10;
    te.conf = 255;
    te.hwaddr = htons(v2);
    l = nw_add_incr_edge(v1, &te);
    l->marked = L_STICKY;
  } else {
    VTY_printf("add a link: '%s <n1> <n2>'\r\n", argv[0]);
  }
  VTY_flush();
}

void nw_inval_node_sh(int fd, int argc, char **argv) {
  VTY_HEAD;
  int int_arg;
  if (argc == 2) {
    int_arg = atoi(argv[1]);
    VTY_printf("invalidating node 0x%x\n", int_arg);
    nw_inval_node(int_arg);
  }
  VTY_flush();
}
//
// helpers
// 

router_t *nw_get_router(node_id_t rid) {
  return hashtable_search(routers, &rid);
}

router_t *get_insert_router(node_id_t rid) {
  router_key_t *key;
  router_t *ret = nw_get_router(rid);
  if (ret == NULL) {
    key = (router_key_t *)malloc(sizeof(router_key_t));
    ret = (router_t *)malloc(sizeof(router_t));
    memset(ret, 0, sizeof(router_t));

    ret->id = rid;
    ret->links = NULL;
    ret->next = router_list;

    ret->reports = 0;
    ret->lastSeqno = -1;

    ret->isProxying = FALSE;
    ret->isController = FALSE;

    ret->sp.dist = FLT_MAX;
    ret->sp.prev = NULL;

    router_list = ret;

    *key = rid;
    hashtable_insert(routers, key, ret);
  }
  return ret;
}


//
// network state API impl.
//

int nw_init() {
  router_t *r;
  links   = create_hashtable(16, hash_link,   link_equal);
  routers = create_hashtable(16, hash_router, router_equal);
  r = get_insert_router(ntohs(__my_address.s6_addr16[7]));
  r->isController = TRUE;
  return 0;
}

/*
 * Adds an observation of the link (v1, v2) to the database.  This
 * implicitly adds the reverse edge for now, as well.
 */
link_t *nw_add_incr_edge(node_id_t v1, struct topology_entry *te) {
  link_key_t key;
  link_t *link_str;
  node_id_t v2 = ntoh16(te->hwaddr);
  key.r1 = v1;
  key.r2 = v2;

  link_str = hashtable_search(links, &key);
  if (link_str == NULL) {
    link_key_t *new_key = (link_key_t *)malloc(sizeof(link_key_t));
    router_t *r1 = get_insert_router(v1);
    router_t *r2 = get_insert_router(v2);
    link_str = (link_t *)malloc(sizeof(link_t));
    memset(link_str, 0, sizeof(link_t));

    new_key->r1 = v1;
    new_key->r2 = v2;

    // point the links at their routers
    link_str->n1 = r1;
    link_str->n2 = r2;
    // add this link to the head of the linked list of edges each router maintains
    link_str->next1 = r1->links;
    link_str->next2 = r2->links;

    link_str->n1_reportcount = 0;
    link_str->n2_reportcount = 0;
    
    r1->links = link_str;
    r2->links = link_str;

    link_str->pc = 0;

    
    hashtable_insert(links, new_key, link_str);

  } 

  link_str->marked = L_REPORTED;
  link_str->qual = ((float)(te->etx)) / 10.0;
  link_str->conf = te->conf;
  debug("nw_add_incr_edge [%i -> %i]: qual: %f conf: %i\n", 
        v1, v2, link_str->qual, link_str->conf);
  (v1 == link_str->n1->id) ? link_str->n1_reportcount++ :
    link_str->n2_reportcount++;

  return link_str;
}

/*
 * Returns a route from v1 to v2 as a linked list.
 *
 * quadratic-time dijkstra implementation: no priority queue
 */
/*
 * relaxes the neighbors of cur
 */
float getMetric(link_t *l) {
  return l->qual;
  //return ((float)l->qual / 3000.0)  + 1.0;
  //return (10. / (float)l->nobs);
}
void update_neighbors(router_t *cur) {
  link_t *l;
  router_t *otherguy;
  // clunky iterator
  for (l = cur->links; l != NULL; l = (cur == l->n1) ? l->next1 : l->next2) {
    otherguy = (cur == l->n1) ? l->n2 : l->n1;
    
    if (cur->sp.dist + getMetric(l) < otherguy->sp.dist) {
      otherguy->sp.dist = cur->sp.dist + getMetric(l);
      otherguy->sp.prev = cur;
    }
  }
}

router_t *extract_min(router_t **list) {
  router_t *r, *prev = NULL, *min = NULL, *prev_min = NULL;
  float min_dist = FLT_MAX;
  for (r = *list; r != NULL; r = r->sp.setptr) {
    if (r->sp.dist < min_dist) {
      min_dist = r->sp.dist;
      min = r;
      prev_min = prev;
    }
    prev = r;
  }

  if (min == NULL) {
    // it might be the case that not everyone is reachable.  In that
    // case, we'll just leave them unconnected.
    *list = NULL;
  } else if (prev_min == NULL) {
    // the first element was the best, set list is pointed at the second element
    *list = (*list)->sp.setptr;
  } else {
    // otherwise just remove the min element from the list
    prev_min->sp.setptr = min->sp.setptr;
  }

  return min;
}

void age_routers() {
  router_t *r;
  int max_reports = 0;
  for (r = router_list; r != NULL; r = r->next) {
    if (r->reports > max_reports) {
      max_reports = r->reports;
    }
    // debug("nwstate: node: %i reports: %i\n", r->id, r->reports);
  }
  if (max_reports == 4) {
    debug("age_routers: max: %i\n", max_reports);
    for (r = router_list; r != NULL; r = r->next) {
      if (r->reports > 0) {
        r->reports = 0;
      } else {
        // debug("nwstate: removing router 0x%x due to age %i\n", r->id, r->reports);
        // nw_inval_node(r->id);
        r->reports = 0;
      }
    }
  }
}

/*
 * compute all destinations shortest path to node v1
 */
void compute_routes(node_id_t v1) {
  router_t *r, *cur = NULL, *not_visited = NULL;
  routes_out_of_date = 0;

  for (r = router_list; r != NULL; r = r->next) {
    r->sp.dist = FLT_MAX;
    r->sp.prev = NULL;
    if (r->id == v1) {
      cur = r;
    } else {
      r->sp.setptr = not_visited;
      not_visited = r;
    }
  }
  if (cur == NULL) return;
  cur->sp.dist = 0;

  while (not_visited != NULL) {
    update_neighbors(cur);
    cur = extract_min (&not_visited);
  }
  // all the prev and distance pointers are now valid.
}

path_t *nw_get_route(node_id_t v1, node_id_t v2) {
  router_t *r, *from, *to;
  path_t *ret = NULL, *new;

  from = hashtable_search(routers, &v1);
  to   = hashtable_search(routers, &v2);

  if (from == NULL || to == NULL) return NULL;

  if (to->sp.prev == NULL || from->sp.prev != NULL || routes_out_of_date) {
    // the current set of shortest paths do not end at node v2, if we
    // haven't computed any paths yet, we will do that when the next
    // test fails.
    debug("nw_get_route: computing new routes\n");
    compute_routes(v1);
  }
  if (to->sp.prev == NULL) return NULL;

  // now the routes should be valid;
  for (r = to; r != NULL; r = r->sp.prev) {
    // this both constructs the return value and reverses the path,
    // since the prev pointers will give you the reverse path.

    // in the future routes will probably be cached.
    
    if (r != from) {
      new = (path_t *)malloc(sizeof(path_t));
      new->node = r->id;
      new->next = ret;
      new->length = (ret == NULL) ? 1 : ret->length + 1;
      new->isController = r->isController;
      ret = new;
    }
  }
  return ret;
}

void nw_free_path(path_t *r) {
  path_t *next;
  while (r != NULL) {
    next = r->next;
    free(r);
    r = next;
  }
}

// remove link from the linked list of links owned by router.
void remove_link(router_t *r, link_t *link) {
  link_t *l;
  link_t **prev = &r->links;
  for (l = r->links; l != NULL; l = (r== l->n1) ? l->next1 : l->next2) {
    if (l == link) {
      *prev = (r == l->n1) ? l->next1 : l->next2;
      return;
    }
    prev = (r == l->n1) ? &l->next1 : &l->next2;
  }
  warn("link_remove: link not removed (inconsistent state)?\n");
}

void nw_remove_link(node_id_t n1, node_id_t n2) {
  router_t *r1 = nw_get_router(n1);
  router_t *r2 = nw_get_router(n2);
  link_t *link;
  link_key_t key;

  key.r1 = n1;
  key.r2 = n2;
  link = hashtable_search(links, &key);
  if (link != NULL) {
    routes_out_of_date = 1;

    remove_link(r1, link);
    remove_link(r2, link);
    hashtable_remove(links, &key);
    free(link);
  }
}

void nw_inval_node(node_id_t v) {
  router_t *cur;
  link_t *l, *next;
  router_t *otherguy;
  link_key_t key;
  routes_out_of_date = 1;

  cur = hashtable_search(routers, &v);
  if (cur == NULL) return;

  // remove the links from the linked lists of the other guys,
  // and delete them from the hashtable
  for (l = cur->links; l != NULL; l = (cur == l->n1) ? l->next1 : l->next2) {
    otherguy = (cur == l->n1) ? l->n2 : l->n1;
    key.r1 = v;
    key.r2 = otherguy->id;
    remove_link(otherguy, l);
    hashtable_remove(links, &key);
  }
  
  // free the link structures
  l = cur->links;
  while (l != NULL) {
    next = (cur == l->n1) ? l->next1 : l->next2;
    free(l);
    l = next;
  }
  cur->links = NULL;

  // force a route recomputation when this node is used.
  cur->sp.dist = FLT_MAX;
  cur->sp.prev = NULL;
}

/*
 * called before adding the topology from a node 
 * unsets the marked bit * in the link structures to show that they
 * have not been reported
 */ 
void nw_unmark_links(node_id_t v) {
  router_t *cur;
  link_t *l;
  routes_out_of_date = 1;

  cur = hashtable_search(routers, &v);
  if (cur == NULL) return;

  for (l = cur->links; l != NULL; l = (cur == l->n1) ? l->next1 : l->next2) {
    if (l->marked == L_REPORTED) l->marked = L_UNREPORTED;
  }

}

void nw_report_node(node_id_t v) {
  router_t *cur;

  cur = hashtable_search(routers, &v);
  if (cur == NULL) return;
  
  cur->reports++;
}

/*
 * called after processing a topology report
 *
 * removes links which were not contained by this topology report, and
 * which were not reported by the router on the other end.
 *
 */
void nw_clear_unmarked(node_id_t v) {
  router_t *cur;
  link_key_t key;
  link_t *l, *next;
  key.r1 = v;

  cur = hashtable_search(routers, &v);
  if (cur == NULL) return;

  for (l = cur->links; l != NULL; l = (cur == l->n1) ? l->next1 : l->next2) {
    if (l->marked == L_UNREPORTED) {
      // it's not marked, so it wasn't contained in the topology report
      if (((cur == l->n1) ? l->n2_reportcount : l->n1_reportcount) == 0) {
        // it has never been reported by the router on the other end, so we
        // remove the link from the topology data
        router_t *otherguy = (cur == l->n1) ? l->n2 : l->n1;
        key.r2 = otherguy->id;
        remove_link(otherguy, l);
        hashtable_remove(links, &key);
        //info("removing unmarked link, 0x%x -> 0x%x\n", cur->id, otherguy->id);
        // remove it from our own linked list
      } else {
        // it has been reported by the other size, so we just set its
        // observation count to zero.
        if (cur == l->n1)  l->n1_reportcount = 0 ;
        else l->n2_reportcount = 0;
        l->marked = L_REPORTED;
        // router_t *otherguy = (cur == l->n1) ? l->n2 : l->n1;
        //debug("unseting obs count on 0x%x -> 0x%x\n", cur->id, otherguy->id);
      }
    }
  }

  // free the links no longer in use
  l = cur->links;
  while (l != NULL) {
    next = (cur == l->n1) ? l->next1 : l->next2;
    // if its still umarked, we mean to remove it from the graph
    if (l->marked == 0) {
      remove_link(cur, l);
      free(l);
    }
    l = next;
  }


  age_routers();
}


void nw_add_controller(node_id_t node) {
  router_t *r, *thisController;

  struct topology_entry te;
  te.etx = 1;
  te.conf = 255;

  thisController = nw_get_router(node);
  if (!thisController) return;

  thisController->isController = TRUE;
  for (r = router_list; r != NULL; r = r->next) {
    if (r->isController && r != thisController) {
      te.hwaddr = htons(r->id);
      nw_add_incr_edge(node, &te);
    }
  }
}
