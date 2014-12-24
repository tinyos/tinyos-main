/*
 * Copyright (c) 2010 Johns Hopkins University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 */

/**
 * RPLRankC.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

/*
 * Copyright (c) 2010 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holder nor the names of
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
 */

/**
 * @author Yiwei Yao <yaoyiwei@stanford.edu>
 */

#ifndef RPL_H
#define RPL_H

#include <iprouting.h>
#include <icmp6.h>
#include <neighbor_discovery.h>

/* SDH : NB : make sure divideRank * BLIP_L2_RETRIES does not
    overflow a uint16_t */
/* SDH : Default eviction threshold set to an etx of "3" -- these are
   pretty bad links. */
/* SDH : the aging parameter \alpha for the link estimator is
   currently hard-coded in RPLRankP.nc.  Last I checked, it was set to
   0.8. */
#if RPL_OF_0
// Threshold at which to evict parent
#define minHopRankIncrease 1
// Divisor for the metric (for fixed-point repr)
#define divideRank 10
#define INIT_ETX divideRank
#define ETX_THRESHOLD (3 * divideRank)
#elif RPL_OF_MRHOF //  MRHOF
#define minHopRankIncrease 128
#define divideRank 128
#define INIT_ETX divideRank //448
#define ETX_THRESHOLD (3 * divideRank)
#endif

#ifndef MAX_PARENT
#define MAX_PARENT 20
#endif

#define MAX_HOPCOUNT 30
#define RPL_QUEUE_SIZE 5
#define RPL_MAX_SOURCEROUTE 10

enum {
  RPL_MOP_No_Downward = 0,
  RPL_MOP_No_Storing = 1,
  RPL_MOP_Storing_No_Multicast = 2,
  RPL_MOP_Storing_With_Multicast = 3,

  RPL_OPT_TYPE_PAD1 = 0,
  RPL_OPT_TYPE_PADN = 1,
  RPL_OPT_TYPE_METRIC = 2,
  RPL_OPT_TYPE_ROUTING = 3,
  RPL_OPT_TYPE_DODAG = 4,
  RPL_OPT_TYPE_TARGET = 5,
  RPL_OPT_TYPE_TRANSIT = 6,
  RPL_OPT_TYPE_SOLICITED = 7,
  RPL_OPT_TYPE_PREFIX = 8,
  RPL_OPT_TYPE_TARGET_DESC = 9,

  RPL_ROUTE_METRIC_ETX = 7,

  RPLOF_OCP_OF0 = 0,
  RPLOF_OCP_MRHOF = 1,
};

enum {
  RPL_IFACE = ROUTE_IFACE_154,
  RPL_HBH_RANK_TYPE = 0x63,     /* per rfc6553 */
};

struct dis_base_t {
  struct icmpv6_header_t icmpv6;
  uint8_t flags;
  uint8_t reserved;
} __attribute__((packed));

struct rpl_instance_id {
  /* Global RPLInstance ID */
  uint8_t id;
}__attribute__((packed));

struct rpl_option_t {
  uint8_t type;
  uint8_t option_length;
} __attribute__((packed));

struct transit_info_option_t {
  uint8_t type;
  uint8_t option_length;
  uint8_t flags;
  uint8_t path_control;
  uint8_t path_sequence;
  uint8_t path_lifetime;
  struct in6_addr parent_address;
} __attribute__((packed));

enum {
  DAO_TRANSIT_E_SHIFT = 7,

  DAO_TRANSIT_E_MASK = 0x80,
};

struct target_option_t {
  uint8_t type;
  uint8_t option_length;
  uint8_t flags;
  uint8_t prefix_length;
  struct in6_addr target_prefix;
} __attribute__((packed));

struct dao_base_t {
  struct icmpv6_header_t icmpv6;
  struct rpl_instance_id instance_id;
  uint8_t flags;
  uint8_t reserved;
  uint8_t DAOsequence;
  struct in6_addr dodagID;
} __attribute__((packed));

struct dao_full_t {
  struct dao_base_t base;
  struct target_option_t target_option;
  struct transit_info_option_t transit_info_option;
} __attribute__((packed));

enum {
  DAO_K_SHIFT = 7,
  DAO_D_SHIFT = 6,

  DAO_K_MASK = 0x80,
  DAO_D_MASK = 0x40,
};

struct dio_base_t {
  struct icmpv6_header_t icmpv6;
  struct rpl_instance_id instance_id;
  uint8_t version;
  nx_uint16_t rank;
  uint8_t flags;
  uint8_t dtsn;
  uint8_t flags_reserved;
  uint8_t reserved;
  struct in6_addr dodagID;
} __attribute__((packed));

enum {
  DIO_G_SHIFT = 7,
  DIO_MOP_SHIFT = 3,
  DIO_PRF_SHIFT = 0,

  DIO_G_MASK = 0x80,
  DIO_MOP_MASK = 0x38,
  DIO_PRF_MASK = 0x07,
};

struct dio_metric_t { // type 2 ; contains metrics
  uint8_t type;
  uint8_t option_length;
} __attribute__((packed));

struct dio_metric_header_t {
  uint8_t routing_mc_type;
  uint8_t reserved_flags;
  uint8_t flags2;
  uint8_t length;
} __attribute__((packed));

enum {
  DIO_METRIC_P_SHIFT = 2,
  DIO_METRIC_C_SHIFT = 1,
  DIO_METRIC_O_SHIFT = 0,
  DIO_METRIC_R_SHIFT = 7,
  DIO_METRIC_A_SHIFT = 4,
  DIO_METRIC_PREC_SHIFT = 0,

  DIO_METRIC_P_MASK = 0x04,
  DIO_METRIC_C_MASK = 0x02,
  DIO_METRIC_O_MASK = 0x01,
  DIO_METRIC_R_MASK = 0x80,
  DIO_METRIC_A_MASK = 0x70,
  DIO_METRIC_PREC_MASK = 0x0F,
};

struct dio_etx_t {
  nx_uint16_t etx;
} __attribute__((packed));

struct dio_latency_t {
  float latency;
} __attribute__((packed));

struct dio_route_info_t { // type 3 ; contains route information
  uint8_t type;
  uint8_t option_length;
  uint8_t reserved_preference;
  nx_uint32_t lifetime;
  struct in6_addr prefix;
} __attribute__((packed));

enum {
  DIO_ROUTE_PRF_SHIFT = 3,

  DIO_ROUTE_PRF_MASK = 0x18,
};

struct dio_dodag_config_t { // type 4 ; contains DODAG configuration
  uint8_t type;
  uint8_t option_length;
  uint8_t reserved_flags;
  nx_uint8_t DIOIntDoubl;
  nx_uint8_t DIOIntMin;
  nx_uint8_t DIORedun;
  nx_uint16_t MaxRankInc;
  nx_uint16_t MinHopRankInc;
  nx_uint16_t ocp;
  nx_uint8_t reserved;
  nx_uint8_t default_lifetime;
  nx_uint16_t lifetime_unit;
} __attribute__((packed));

enum {
  DIO_DODAG_A_SHIFT = 3,
  DIO_DODAG_PCS_SHIFT = 0,

  DIO_DODAG_A_MASK = 0x08,
  DIO_DODAG_PCS_MASK = 0x07,
};

struct dio_prefix_t { // type 8 ; contains prefix information
  uint8_t type;
  uint8_t option_length;
  uint8_t prefix_length;
  uint8_t flags_reserved;
  nx_uint32_t valid_lifetime;
  nx_uint32_t preferred_lifetime;
  uint32_t reserved2;
  struct in6_addr prefix;
} __attribute__((packed));

enum {
  DIO_PREFIX_L_SHIFT = 7,
  DIO_PREFIX_A_SHIFT = 6,
  DIO_PREFIX_R_SHIFT = 5,

  DIO_PREFIX_L_MASK = 0x80,
  DIO_PREFIX_A_MASK = 0x40,
  DIO_PREFIX_R_MASK = 0x20,
};

/* Necessary constants for RPL*/
uint16_t ROOT_RANK = 1;
enum {
  BASE_RANK = 0,
  INFINITE_RANK = 0xFFFF,
  RPL_DEFAULT_INSTANCE = 0,
  NUMBER_OF_PARENTS = 10,
  DIS_INTERVAL = 3*1024U,
  //DEFAULT_LIFETIME = 1024L * 60 * 20, // 20 mins
  //DEFAULT_LIFETIME = 0xFF, // all ones for now
  DEFAULT_LIFETIME = 0xCC, // some other value
};

/*RFC defined parameters*/
enum {
  ICMPV6_TYPE = 58,
};

enum {
  ICMPV6_CODE_DIS = 0x00,
  ICMPV6_CODE_DIO = 0x01,
  ICMPV6_CODE_DAO = 0x02,
};

enum {
  DIO_BASE_FLAG_GRD = 0,
  DIO_BASE_FLAG_DA_TRIGGER = 1,
  DIO_BASE_FLAG_DA_SUPPORT = 2,
  DIO_BASE_FLAG_PREF_5 = 5,
  DIO_BASE_FLAG_PREF_6 = 6,
  DIO_BASE_FLAG_PREF_7 = 7,
};

///////////////////////// for forwarding engine //////////////////////////////

typedef struct {
  struct in6_addr next_hop;
  uint8_t* data;
} rpl_data_packet_t;

typedef struct {
  struct ip6_hdr iphdr;
  uint8_t retries;
  rpl_data_packet_t packet;
} queue_entry_t;

typedef struct {
  struct ip6_packet s_pkt;
  struct dao_full_t dao_full;
  struct ip_iovec v[1];
} dao_entry_t;

typedef struct {
  struct in6_addr nodeID;
  uint8_t interfaceID;
  uint8_t DAOsequence;
  //uint16_t DAOrank;
  uint32_t DAOlifetime;
  uint8_t routeTag;
  uint8_t RRlength;
  uint8_t prefixLength;
  struct in6_addr prefix;
  uint8_t* RRStack;
} dao_table_entry;

typedef struct {
  struct in6_addr nodeID;
  uint16_t successTx;
  uint16_t totalTx;
  uint16_t etx;
} parentTableEntryDAO;

typedef struct {
  route_key_t key;
  uint32_t lifetime;
} downwards_table_t;


nx_struct nx_ip6_ext {
  nx_uint8_t ip6e_nxt;
  nx_uint8_t ip6e_len;
};

/* draft-ietf-6man-rpl-option-01 */
typedef nx_struct {
  nx_struct nx_ip6_ext ip6_ext_outer;
  nx_struct nx_ip6_ext ip6_ext_inner;
  nx_uint8_t bitflag;
  // nx_struct rpl_instance_id instance_id; // used to be instanceID
  nx_uint8_t instance_id;
  nx_uint16_t senderRank;
} __attribute__((packed)) rpl_data_hdr_t ;

#define RPL_DATA_O_BIT_MASK 0x80
#define RPL_DATA_O_BIT_SHIFT 7
#define RPL_DATA_R_BIT_MASK 0x40
#define RPL_DATA_R_BIT_SHIFT 6
#define RPL_DATA_F_BIT_MASK 0x20
#define RPL_DATA_F_BIT_SHIFT 5

//////////////////////////////////////////////////////////////////////////////

/////////////////////// for rank component ///////////////////////////////////

typedef struct {
  struct in6_addr parentIP;
  uint16_t rank;
  //uint16_t successNum;
  //uint16_t totalNum;
  uint16_t etx;
  uint16_t etx_hop;
  //float latency;
  bool valid;
} parent_t;

struct dio_dest_prefix_t {
  uint8_t type;
  uint16_t length;
  uint8_t* data;
};

#endif
