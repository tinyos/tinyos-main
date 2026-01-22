
#ifndef NEIGHBR_H
#define NEIGHBR_H

#include "ND.h"

/* Neighbor Cache (RFC 4861 Section 5.1)

 Description: Contains set of entries about individual neighbors to which traffic has been sent recently
*/



typedef struct neigbr_info_t {
  uint8_t isRouter;			//flag indicating whether the neighbor is Router or not	
  uint32_t next_ndtime;		//Time after which the next Neighbor Unreachability Detection event is scheduled(millisec)
  uint8_t type;			//type of the neighbour cache entry such as TENTATIVE,REGISTERED
  uint8_t state;			//Reachability States such as REACHABLE,STALE,INCOMPLETE,DELAY and PROBE
  uint32_t timer;			//time upto which the neighbor is valid(secs)
  uint8_t reserved;			//checking any padding is required
}__attribute__((packed)) neighbr_info;


typedef struct   neighbr_cache_t {

  struct in6_addr ip_address;		//IPv6 address of the neighbour
  ieee_eui64_t  linklayer_addr;	//link layer address of the neighbour
  neighbr_info info;
}__attribute__((packed)) neighbr_cache;

/* Default Router List(RFC 4861 Section 5.1)

  Description:  Contains a set of entries of routers to which the packets may be sent.Router list Entries point to the entries in the Neighbor Cache.*/

typedef struct   default_rtrlist_t {
  neighbr_cache *rtr;	//pointer to the neighbour cache entry
}__attribute__((packed)) default_rtrlist;


/*DAD Table(RFC 4861 Section 8.2.3)
  Description: Table Maintained by the 6LBR. Each entry contains an IPv6 address(Registered Address in the DAR) ,EUI-64 and Registration Lifetime of the host */


typedef struct dad_cache_t {
  struct in6_addr ip_address;	//registered address in the DAR
  ieee_eui64_t linklayer_addr;
  uint16_t reg_lifetime;
}__attribute__((packed)) dad_cache;


/* Storing Prefix Information */


typedef struct {
 prefix_info prefix_information;
 abro_info  abro_information;
 uint8_t cid;
 uint16_t context_lifetime;
}__attribute__((packed))prefix_list;



#ifndef NEIGHBR_TABLE_SZ 
#define NEIGHBR_TABLE_SZ 10
#endif


#ifndef DAD_TABLE_SZ
#define DAD_TABLE_SZ 10
#endif

#ifndef PREFIX_TABLE_SZ
#define PREFIX_TABLE_SZ 3
#endif

#ifndef ROUTER_TABLE_SZ
#define ROUTER_TABLE_SZ 2
#endif
	
enum
{
  TENTATIVE=1,
  REGISTERED=2,
  GARBAGE_COLLECTIBLE=3,
  NP=4,
};

/*TENTATIVE_NCE_LIFETIME: A Tentative NCE should be timed out TENTATIVE_NCE_LIFETIME seconds after it was created in order to 
allow for another host to attempt to register the IPv6 Address*/
#define TENTATIVE_NCE_LIFETIME	2	//2 Minutes
#define MAX_RTRS 2
#endif




