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
#ifndef _IPDISPATCH_H_
#define _IPDISPATCH_H_

#include <message.h>
#include <lib6lowpan.h>
#include <Statistics.h>

enum {
  N_PARENTS = 3,
  N_EPOCHS = 2,
  N_EPOCHS_COUNTED = 1,
  N_RECONSTRUCTIONS = 2,
  N_FORWARD_ENT = IP_NUMBER_FRAGMENTS,
};

enum {
  CONF_EVICT_THRESHOLD = 5, // Neighbor is 'mature'
  CONF_PROM_THRESHOLD = 5, // Acceptable threshold for promotion
  MAX_CONSEC_FAILURES = 11, // Max Failures before reroute is attempted
  PATH_COST_DIFF_THRESH = 10, // Threshold for 'similar' path costs
  LQI_DIFF_THRESH = 10, // Threshold for 'similar' LQI's
  LINK_EVICT_THRESH = 50, // ETX * 10
  LQI_ADMIT_THRESH = 0x200, 
  RSSI_ADMIT_THRESH = 0,
  RANDOM_ROUTE = 20, //Percentage of time to select random default route
};

enum {
  WITHIN_THRESH = 1,
  ABOVE_THRESH = 2,
  BELOW_THRESH = 3,
};

#ifndef LOW_POWER_LISTENING
enum {
  TGEN_BASE_TIME = 512,
  TGEN_MAX_INTERVAL = 60L * 1024L * 5L,
};
#else
enum {
  TGEN_BASE_TIME = 16384L,
  TGEN_MAX_INTERVAL = 60L * 1024L * 5L,
};
#endif


struct epoch_stats {
  uint16_t success;
  uint16_t total;
  uint16_t receptions;
};

struct report_stats {
  uint8_t messages;
  uint8_t transmissions;
  uint8_t successes;
};

enum {
  T_PIN_OFFSET    = 0,
  T_PIN_MASK      = 1 << T_PIN_OFFSET,
  T_VALID_OFFSET  = 2,
  T_VALID_MASK    = 1 << T_VALID_OFFSET,
  T_MARKED_OFFSET = 3,
  T_MARKED_MASK   = 1 << T_MARKED_OFFSET,
  T_MATURE_OFFSET = 4,
  T_MATURE_MASK   = 1 << T_MATURE_OFFSET,
  T_EVICT_OFFSET  = 5,
  T_EVICT_MASK    = 1 << T_EVICT_OFFSET,
};

enum {
  // store the top-k neighbors.  This could be a poor topology
  // formation critera is very dense networks.  we may be able to
  // really use the fact that the "base" has infinite memory.
  N_NEIGH = 8,
  N_LOW_NEIGH = 2,
  N_FREE_NEIGH = (N_NEIGH - N_LOW_NEIGH),
  N_FLOW_ENT = 6,
  N_FLOW_CHOICES = 2,
  N_PARENT_CHOICES = 3,
  T_DEF_PARENT = 0xfffd,
  T_DEF_PARENT_SLOT = 0,
};

typedef struct {
  // The extra 2 is because one dest could be from source route, other
  //  from the dest being a direct neighbor
  ieee154_saddr_t dest[N_FLOW_CHOICES + N_PARENT_CHOICES + 2];
  uint8_t   current:4;
  uint8_t   nchoices:4;
  uint8_t   retries;
  uint8_t   actRetries;
  uint16_t  delay;
} send_policy_t;

typedef struct {
  send_policy_t policy;
  uint8_t frags_sent;
  bool failed;
  uint8_t refcount;
  uint8_t local_flow_label;
} send_info_t;

typedef struct {
  send_info_t *info;
  message_t  *msg;
} send_entry_t;

typedef struct {
  uint8_t timeout;
  ieee154_saddr_t l2_src;
  uint16_t old_tag;
  uint16_t new_tag;
  send_info_t *s_info;
} forward_entry_t;

/* typedef struct { */
/*   /\* how to dispatch this packet *\/ */
/*   union { */
/*     struct sockaddr_in6 sock; */
/*     ip6_addr_t src; */
/*   } address; */
/*   /\* packet metadata *\/ */
/*   union { */
/*     uint16_t udp_port; */
/*   } dispatch; */
/*   struct ip_metadata metadata; */

/*   /\* the lib6lowpan reconstruct structure *\/ */
/*   reconstruct_t recon; */
/* } ip_recon_t; */

enum {
  F_VALID_MASK = 0x01,
  //F_TOTAL_VALID_ENTRY_MASK = 0x80, // For entire entry (not just specific choice)
  F_FULL_PATH_OFFSET = 1,
  F_FULL_PATH_MASK = 0x02,

  MAX_PATH_LENGTH = 10,
  N_FULL_PATH_ENTRIES = (N_FLOW_CHOICES * N_FLOW_ENT),
};
  
struct flow_path {
  uint8_t path_len;
  cmpr_ip6_addr_t path[MAX_PATH_LENGTH];
};

struct f_entry {
  uint8_t flags;
  union {
    struct flow_path *pathE;
    cmpr_ip6_addr_t nextHop;
  };
};

// Need to add another entry to avoid useless padding
//  Or can make sure that the flow_table has an even
//  number of entries.
struct flow_entry {
  uint8_t flags;
  uint8_t count;
  struct flow_match match;
  struct f_entry entries[N_FLOW_CHOICES];
};

//#define IS_VALID_SLOT(f) (((f)->entries[0].flags & F_TOTAL_VALID_ENTRY_MASK) == F_TOTAL_VALID_ENTRY_MASK)
#define IS_VALID_SLOT(f) (((f)->flags & F_VALID_MASK) == F_VALID_MASK)
//#define SET_VALID_SLOT(f) (f)->entries[0].flags |= F_TOTAL_VALID_ENTRY_MASK
#define SET_VALID_SLOT(f) (f)->flags |= F_VALID_MASK
//#define SET_INVALID_SLOT(f) (f)->entries[0].flags &= ~F_TOTAL_VALID_ENTRY_MASK
#define SET_INVALID_SLOT(f) (f)->flags &= ~F_VALID_MASK
#define IS_VALID_ENTRY(e) (((e).flags & F_VALID_MASK) == F_VALID_MASK)
#define SET_VALID_ENTRY(e) (e).flags |= F_VALID_MASK
#define SET_INVALID_ENTRY(e) (e).flags &= ~F_VALID_MASK
#define IS_FULL_TYPE(e) (((e).flags & F_FULL_PATH_MASK) == F_FULL_PATH_MASK)
#define IS_HOP_TYPE(e) !IS_FULL_TYPE(e)
#define SET_FULL_TYPE(e) ((e).flags |= F_FULL_PATH_MASK)
#define SET_HOP_TYPE(e) ((e).flags &= ~F_FULL_PATH_MASK)
  

struct neigh_entry {
  uint8_t flags;
  uint8_t hops; // Put this before neighbor to remove potential padding issues
  ieee154_saddr_t neighbor;
  uint16_t costEstimate;
  uint16_t linkEstimate;
  struct epoch_stats stats[N_EPOCHS];
}
#ifdef MIG
 __attribute__((packed));
#else
;
#endif

#define IS_NEIGH_VALID(e) (((e)->flags & T_VALID_MASK) == T_VALID_MASK)
#define SET_NEIGH_VALID(e) ((e)->flags |= T_VALID_MASK)
#define SET_NEIGH_INVALID(e) ((e)->flags &= ~T_VALID_MASK)
#define PINNED(e) (((e)->flags & T_PIN_MASK) == T_PIN_MASK)
#define REMOVABLE(e) (((e)->refCount == 0) && !(PINNED(e)))
#define SET_PIN(e) (((e)->flags |= T_PIN_MASK))
#define UNSET_PIN(e) (((e)->flags &= ~T_PIN_MASK))
#define IS_MARKED(e) (((e)->flags & T_MARKED_MASK) == T_MARKED_MASK)
#define SET_MARK(e) (((e)->flags |= T_MARKED_MASK))
#define UNSET_MARK(e) (((e)->flags &= ~T_MARKED_MASK))
#define IS_MATURE(e) (((e)->flags & T_MATURE_MASK) == T_MATURE_MASK)
#define SET_MATURE(e) ((e)->flags |= T_MATURE_MASK)
#define SET_EVICT(e) ((e).flags |= T_EVICT_MASK)
#define UNSET_EVICT(e) ((e).flags &= ~T_EVICT_MASK)
#define SHOULD_EVICT(e) ((e).flags & T_EVICT_MASK)


typedef enum {
  S_FORWARD,
  S_REQ,
} send_type_t;


#endif
