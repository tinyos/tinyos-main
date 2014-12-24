/*
 * Data structures for Neighbor Discovery.
 *
 * RFC6775, RFC4861, RFC4862
 *
 * @author Brad Campbell <bradjc@umich.edu>
 */

#ifndef NEIGHBOR_DISCOVERY_H
#define NEIGHBOR_DISCOVERY_H

#include <iprouting.h>
#include <icmp6.h>

#define IPV6_ADDR_ALL_ROUTERS "ff02::2"

enum {
  ICMPV6_CODE_RS = 0x00,
  ICMPV6_CODE_RA = 0x00,
  ICMPV6_CODE_NS = 0x00,
  ICMPV6_CODE_NA = 0x00
};

enum {
  ND6_OPT_SLLAO = 1,
  ND6_OPT_TLLAO = 2,
  ND6_OPT_PREFIX = 3,
  ND6_OPT_REDIRECT_HEADER = 4,
  ND6_OPT_MTU = 5
};

enum {
  RA_FLAG_MANAGED_ADDR_CONF = 0,
  RA_FLAG_OTHER_CONF = 0
};

struct nd_router_solicitation_t {
  struct icmpv6_header_t icmpv6;
  nx_uint32_t reserved;
};

struct nd_router_advertisement_t {
  struct icmpv6_header_t icmpv6;
  uint8_t hop_limit;
  uint8_t flags_reserved;
  nx_uint16_t router_lifetime;
  nx_uint32_t reachable_time;
  nx_uint32_t retransmit_time;
};

struct nd_neighbor_solicitation_t {
  struct icmpv6_header_t icmpv6;
  nx_uint32_t reserved;
  struct in6_addr target_address;
};

struct nd_neighbor_advertisement_t {
  struct icmpv6_header_t icmpv6;
  uint8_t flags;
  uint8_t reserved1;
  nx_uint16_t reserved2;
  struct in6_addr target_address;
};

enum {
  ND6_RADV_M_SHIFT = 7,
  ND6_RADV_O_SHIFT = 6,

  ND6_RADV_M_MASK = 0x80,
  ND6_RADV_O_MASK = 0x40,

  ND6_NADV_R_SHIFT = 7,
  ND6_NADV_S_SHIFT = 6,
  ND6_NADV_O_SHIFT = 5,

  ND6_NADV_R_MASK = 0x80,
  ND6_NADV_S_MASK = 0x40,
  ND6_NADV_O_MASK = 0x20,
};

// source link-layer address option
struct nd_option_slla_t {
  uint8_t type;
  uint8_t option_length;
  ieee154_laddr_t ll_addr; // use 8 byte link-layer address
};

// prefix information option
struct nd_option_prefix_info_t {
  uint8_t type;
  uint8_t option_length;
  uint8_t prefix_length;
  uint8_t flags_reserved;
  nx_uint32_t valid_lifetime;
  nx_uint32_t preferred_lifetime;
  uint32_t reserved2;
  struct in6_addr prefix;
};

enum {
  ND6_OPT_PREFIX_L_SHIFT = 7,
  ND6_OPT_PREFIX_A_SHIFT = 6,

  ND6_OPT_PREFIX_L_MASK = 0x80,
  ND6_OPT_PREFIX_A_MASK = 0x40,
};

struct nd_option_redirected_header_t {
  uint8_t type;
  uint8_t option_length;
  uint16_t reserved;
  uint32_t reserved2;
  // IP Header + data
};

struct nd_option_mtu_t {
  uint8_t type;
  uint8_t option_length;
  uint16_t reserved;
  nx_uint32_t mtu;
};

enum {
  PREFIX_TABLE_SZ = 10,
};

struct nd_prefix_t {
  bool valid;
  uint8_t length; //bits
  uint8_t flags;
  uint32_t valid_lifetime;
  uint32_t preferred_lifetime;
  struct in6_addr prefix;
};

enum {
  IP6_INFINITE_LIFETIME = 0xFFFFFFFF,

  MAX_RTR_SOLICITATIONS = 3,
  RTR_SOLICITATION_INTERVAL = 10*1024U,
  MAX_RTR_SOLICITATION_INTERVAL = 60*1024U,

  RTR_LIFETIME = 0xFFFF
};



#endif
