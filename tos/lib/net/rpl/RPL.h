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

/* SDH : NB : make sure divideRank * BLIP_L2_RETRIES does not
    overflow a uint16_t */
/* SDH : Default eviction threshold set to an etx of "3" -- these are
   pretty bad links. */
/* SDH : the aging parameter \alpha for the link estimator is
   currently hard-coded in RPLRankP.nc.  Last I checked, it was set to
   0.8. */
#ifndef RPL_OF_MRHOF
// Threshold at which to evict parent
#define minHopRankIncrease 1
// Divisor for the metric (for fixed-point repr)
#define divideRank 10 
#define INIT_ETX divideRank 
#define ETX_THRESHOLD (3 * divideRank)
#else //  MRHOF
#define minHopRankIncrease 128
#define divideRank 128
#define INIT_ETX divideRank //448
#define ETX_THRESHOLD (3 * divideRank)
#endif // MRHOF

#define MAX_PARENT 20
#define MAX_HOPCOUNT 30
#define RPL_QUEUE_SIZE 5
#define RPL_MAX_SOURCEROUTE 10

enum {
  RPL_DODAG_METRIC_CONTAINER_TYPE = 2,
  RPL_DST_PREFIX_TYPE = 3,
  RPL_DODAG_CONFIG_TYPE = 4,
  RPL_TARGET_TYPE = 5,
  RPL_TRANSIT_INFORMATION_TYPE = 6,
  RPL_MOP_No_Downward = 0,
  RPL_MOP_No_Storing = 1,
  RPL_MOP_Storing_No_Multicast = 2,
  RPL_MOP_Storing_With_Multicast = 3,

  RPL_DIO_TYPE_METRIC = 2,
  RPL_DIO_TYPE_ROUTING = 3,
  RPL_DIO_TYPE_DODAG = 4,
  RPL_DIO_TYPE_PREFIX = 8,

  RPL_ROUTE_METRIC_ETX = 7,

  RPLOF_OCP_OF0 = 0,
  RPLOF_OCP_MRHOF = 1,
};

enum {
  RPL_IFACE = ROUTE_IFACE_154,
  RPL_HBH_RANK_TYPE = 0x6b,     /* per draft-ietf-6man-rpl-option-02 */
};

struct icmpv6_header_t {
  uint8_t	type;
  uint8_t	code;
  nx_uint16_t	checksum;
}__attribute__((packed));

struct dis_base_t {
  struct icmpv6_header_t icmpv6;
  nx_uint16_t reserved;
};

struct rpl_instance_id {
  /* Global RPLInstance ID */
  uint8_t id;
}__attribute__((packed));

struct transit_info_option_t {
  uint8_t type;
  uint8_t option_length;
  uint8_t path_sequence;
  uint8_t path_control;
  uint32_t path_lifetime;
  struct in6_addr parent_address;
};

struct target_option_t {
  uint8_t type;
  uint8_t option_length;
  uint8_t reserved;
  uint8_t prefix_length;
  struct in6_addr target_prefix;
};

struct dao_base_t {
  struct icmpv6_header_t icmpv6;
  struct rpl_instance_id instance_id; // used to be RPLinstanceID
  uint16_t k_bit : 1;
  uint16_t d_bit : 1;
  uint16_t flags : 6;
  uint16_t reserved : 8;
  uint8_t DAOsequence;
  struct in6_addr dodagID;
  struct target_option_t target_option;
  struct transit_info_option_t transit_info_option;
}__attribute__((packed));

struct dio_base_t {
  struct icmpv6_header_t icmpv6;
  struct rpl_instance_id instance_id; // used to be instanceID
  nx_uint8_t version; //used to be sequence
  nx_uint16_t dagRank;
  uint8_t flags;
  uint8_t dtsn;
  nx_uint16_t reserved;
  struct in6_addr dodagID; // was dagID
}__attribute__((packed));

struct dio_body_t{ // type 2 ; contains metrics
  uint8_t type;
  uint8_t container_len;
  //uint8_t *metric_data;
};

struct dio_dodag_config_t{ // type 4 ; contains DODAG configuration
  nx_uint8_t type;
  nx_uint8_t length;
  uint8_t flags : 4;
  uint8_t A     : 1;
  uint8_t PCS   : 3;
  nx_uint8_t DIOIntDoubl;
  nx_uint8_t DIOIntMin;
  nx_uint8_t DIORedun;
  nx_uint16_t MaxRankInc;
  nx_uint16_t MinHopRankInc;
  nx_uint16_t ocp;
  nx_uint8_t reserved;
  nx_uint8_t default_lifetime;
  nx_uint16_t lifetime_unit;
};

struct dio_metric_header_t{ 
  uint8_t routing_obj_type;
  uint8_t reserved    :  2;
  uint8_t R_flag      :  1;
  uint8_t G_flag      :  1;
  uint8_t A_flag      :  2;
  uint8_t O_flag      :  1;
  uint8_t C_flag      :  1;
  nx_uint16_t object_len;
};

struct dio_etx_t{
  nx_uint16_t etx;
};

struct dio_latency_t{
  float latency;
};

struct dio_prefix_t{
  uint8_t type;
  nx_uint16_t suboption_len;
  uint8_t reserved : 3;
  uint8_t preference : 2;
  uint8_t reserved2 : 3;
  nx_uint32_t lifetime;
  uint8_t prefix_len;
  struct in6_addr prefix;
};

struct rpl_route {
  uint8_t next_header;
  uint8_t hdr_ext_len;
  uint8_t routing_type;
  uint8_t segments_left;
  uint8_t compr : 4;
  uint8_t pad   : 4;
  uint8_t reserved;
  uint16_t reserved1;
  struct in6_addr addr[RPL_MAX_SOURCEROUTE];
};

/* Necessary constants for RPL*/
uint16_t ROOT_RANK = 1;
enum {
  BASE_RANK = 0,
  INFINITE_RANK = 0xFFFF,
  RPL_DEFAULT_INSTANCE = 0,
  NUMBER_OF_PARENTS = 10,
  DIS_INTERVAL = 3*1024U,
  DEFAULT_LIFETIME = 1024L * 60 * 20, // 20 mins
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

enum {
  DIO_BASE_OPT_PAD1 = 0,
  DIO_BASE_OPT_PADN = 1,
  DIO_BASE_OPT_DAG_METRIC = 2,
  DIO_BASE_OPT_DST_PREFIX = 3,
  DIO_BASE_OPT_DAG_TIMER_CONFIG = 4,
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
  struct dao_base_t dao_base;
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

#define DIO_GROUNDED_MASK 0x80
#define DIO_MOP_MASK 0x3c
#define DIO_MOP_SHIFT 3
#define DIO_PREF_MASK 0x07
#define DIO_PREF_SHIFT 0

#endif
