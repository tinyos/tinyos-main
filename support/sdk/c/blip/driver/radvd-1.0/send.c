/*
 *   $Id: send.c,v 1.4 2009-08-20 17:03:05 sdhsdh Exp $
 *
 *   Authors:
 *    Pedro Roque		<roque@di.fc.ul.pt>
 *    Lars Fenneberg		<lf@elemental.net>	 
 *
 *   This software is Copyright 1996,1997 by the above mentioned author(s), 
 *   All Rights Reserved.
 *
 *   The license which is distributed with this software in the file COPYRIGHT
 *   applies to this software. If your distribution is missing this file, you
 *   may request it from <pekkas@netcore.fi>.
 *
 */

#include "config.h"
#include "includes.h"
#include "radvd.h"


uint16_t routing_get_seqno();

#define ICMP_EXT_TYPE_BEACON 17

/* SDH : copied from ICMP.h */
struct AdvMetric {
  uint8_t type;
  uint8_t length;
  uint16_t metric;
  uint16_t seqno;
  uint8_t pad[2];
};


void
send_ra(int sock, struct Interface *iface, struct in6_addr *dest)
{
	uint8_t all_hosts_addr[] = {0xff,0x02,0,0,0,0,0,0,0,0,0,0,0,0,0,1};
	struct sockaddr_in6 addr;
	struct in6_pktinfo *pkt_info;
	struct msghdr mhdr;
	struct cmsghdr *cmsg;
	struct iovec iov;
	char chdr[CMSG_SPACE(sizeof(struct in6_pktinfo))];
	struct nd_router_advert *radvert;
	struct AdvPrefix *prefix;
	struct AdvRoute *route;
	struct AdvRDNSS *rdnss;
	/* XXX: we don't keep track if buff gets overflowed.  In theory the sysadmin could
	   do that with e.g., too many advertised prefixes or routes, but buff is just so
	   large that this should never happen and if it does, it's admin's fault :-)  */
	unsigned char buff[MSG_SIZE];
	int len = 0;
	int err;

	/* First we need to check that the interface hasn't been removed or deactivated */
	if(check_device(sock, iface) < 0) {
		if (iface->IgnoreIfMissing)  /* a bit more quiet warning message.. */
			dlog(LOG_DEBUG, 4, "interface %s does not exist, ignoring the interface", iface->Name);
		else {
			flog(LOG_WARNING, "interface %s does not exist, ignoring the interface", iface->Name);
		}
		iface->HasFailed = 1;
	} else {
		/* check_device was successful, act if it has failed previously */
		if (iface->HasFailed == 1) {
			flog(LOG_WARNING, "interface %s seems to have come back up, trying to reinitialize", iface->Name);
			iface->HasFailed = 0;
			/* XXX: reinitializes 'iface', so this probably isn't going to work until next send_ra().. */
                        /* SDH : don't do this since we're not doing config the same way */
			/* reload_config(); */
		}
	}

	/* Make sure that we've joined the all-routers multicast group */
	if (check_allrouters_membership(sock, iface) < 0)
		flog(LOG_WARNING, "problem checking all-routers membership on %s", iface->Name);

	dlog(LOG_DEBUG, 3, "sending RA on %s", iface->Name);

	if (dest == NULL)
	{
		struct timeval tv;

		dest = (struct in6_addr *)all_hosts_addr;
		gettimeofday(&tv, NULL);

		iface->last_multicast_sec = tv.tv_sec;
		iface->last_multicast_usec = tv.tv_usec;
	}
	
	memset((void *)&addr, 0, sizeof(addr));
	addr.sin6_family = AF_INET6;
	addr.sin6_port = htons(IPPROTO_ICMPV6);
	memcpy(&addr.sin6_addr, dest, sizeof(struct in6_addr));

	memset(&buff, 0, sizeof(buff));
	radvert = (struct nd_router_advert *) buff;

	radvert->nd_ra_type  = ND_ROUTER_ADVERT;
	radvert->nd_ra_code  = 0;
	radvert->nd_ra_cksum = 0;

	radvert->nd_ra_curhoplimit	= iface->AdvCurHopLimit;
	radvert->nd_ra_flags_reserved	= 
		(iface->AdvManagedFlag)?ND_RA_FLAG_MANAGED:0;
	radvert->nd_ra_flags_reserved	|= 
		(iface->AdvOtherConfigFlag)?ND_RA_FLAG_OTHER:0;
	/* Mobile IPv6 ext */
	radvert->nd_ra_flags_reserved   |=
		(iface->AdvHomeAgentFlag)?ND_RA_FLAG_HOME_AGENT:0;

	/* if forwarding is disabled, send zero router lifetime */
        /* SDH : disable this check too */
	/* radvert->nd_ra_router_lifetime	 =  !check_ip6_forwarding() ? htons(iface->AdvDefaultLifetime) : 0; */
	radvert->nd_ra_flags_reserved   |=
		(iface->AdvDefaultPreference << ND_OPT_RI_PRF_SHIFT) & ND_OPT_RI_PRF_MASK;

	radvert->nd_ra_reachable  = htonl(iface->AdvReachableTime);
	radvert->nd_ra_retransmit = htonl(iface->AdvRetransTimer);

	len = sizeof(struct nd_router_advert);

	prefix = iface->AdvPrefixList;

	/*
	 *	add prefix options
	 */

	while(prefix)
	{
		if( prefix->enabled )
		{
			struct nd_opt_prefix_info *pinfo;
			
			pinfo = (struct nd_opt_prefix_info *) (buff + len);

			pinfo->nd_opt_pi_type	     = ND_OPT_PREFIX_INFORMATION;
			pinfo->nd_opt_pi_len	     = 4;
			pinfo->nd_opt_pi_prefix_len  = prefix->PrefixLen;
			
			pinfo->nd_opt_pi_flags_reserved  = 
				(prefix->AdvOnLinkFlag)?ND_OPT_PI_FLAG_ONLINK:0;
			pinfo->nd_opt_pi_flags_reserved	|=
				(prefix->AdvAutonomousFlag)?ND_OPT_PI_FLAG_AUTO:0;
			/* Mobile IPv6 ext */
			pinfo->nd_opt_pi_flags_reserved |=
				(prefix->AdvRouterAddr)?ND_OPT_PI_FLAG_RADDR:0;

			pinfo->nd_opt_pi_valid_time	= htonl(prefix->AdvValidLifetime);
			pinfo->nd_opt_pi_preferred_time = htonl(prefix->AdvPreferredLifetime);
			pinfo->nd_opt_pi_reserved2	= 0;
			
			memcpy(&pinfo->nd_opt_pi_prefix, &prefix->Prefix,
			       sizeof(struct in6_addr));

			len += sizeof(*pinfo);
		}

		prefix = prefix->next;
	}
	
	route = iface->AdvRouteList;

	/*
	 *	add route options
	 */

	while(route)
	{
		struct nd_opt_route_info_local *rinfo;
		
		rinfo = (struct nd_opt_route_info_local *) (buff + len);

		rinfo->nd_opt_ri_type	     = ND_OPT_ROUTE_INFORMATION;
		/* XXX: the prefixes are allowed to be sent in smaller chunks as well */
		rinfo->nd_opt_ri_len	     = 3;
		rinfo->nd_opt_ri_prefix_len  = route->PrefixLen;
			
		rinfo->nd_opt_ri_flags_reserved  =
			(route->AdvRoutePreference << ND_OPT_RI_PRF_SHIFT) & ND_OPT_RI_PRF_MASK;
		rinfo->nd_opt_ri_lifetime	= htonl(route->AdvRouteLifetime);
			
		memcpy(&rinfo->nd_opt_ri_prefix, &route->Prefix,
		       sizeof(struct in6_addr));
		len += sizeof(*rinfo);

		route = route->next;
	}
	
	rdnss = iface->AdvRDNSSList;
	
	/*
	 *	add rdnss options
	 */

	while(rdnss)
	{
		struct nd_opt_rdnss_info_local *rdnssinfo;
		
		rdnssinfo = (struct nd_opt_rdnss_info_local *) (buff + len);

		rdnssinfo->nd_opt_rdnssi_type	     = ND_OPT_RDNSS_INFORMATION;
		rdnssinfo->nd_opt_rdnssi_len	     = 1 + 2*rdnss->AdvRDNSSNumber;
		rdnssinfo->nd_opt_rdnssi_pref_flag_reserved = 
		((rdnss->AdvRDNSSPreference << ND_OPT_RDNSSI_PREF_SHIFT) & ND_OPT_RDNSSI_PREF_MASK);
		rdnssinfo->nd_opt_rdnssi_pref_flag_reserved |=
		((rdnss->AdvRDNSSOpenFlag)?ND_OPT_RDNSSI_FLAG_S:0);

		rdnssinfo->nd_opt_rdnssi_lifetime	= htonl(rdnss->AdvRDNSSLifetime);
			
		memcpy(&rdnssinfo->nd_opt_rdnssi_addr1, &rdnss->AdvRDNSSAddr1,
		       sizeof(struct in6_addr));
		memcpy(&rdnssinfo->nd_opt_rdnssi_addr2, &rdnss->AdvRDNSSAddr2,
		       sizeof(struct in6_addr));
		memcpy(&rdnssinfo->nd_opt_rdnssi_addr3, &rdnss->AdvRDNSSAddr3,
		       sizeof(struct in6_addr));
		len += sizeof(*rdnssinfo) - (3-rdnss->AdvRDNSSNumber)*sizeof(struct in6_addr);

		rdnss = rdnss->next;
	}
	
	/*
	 *	add MTU option
	 */

	if (iface->AdvLinkMTU != 0) {
		struct nd_opt_mtu *mtu;
		
		mtu = (struct nd_opt_mtu *) (buff + len);
	
		mtu->nd_opt_mtu_type     = ND_OPT_MTU;
		mtu->nd_opt_mtu_len      = 1;
		mtu->nd_opt_mtu_reserved = 0; 
		mtu->nd_opt_mtu_mtu      = htonl(iface->AdvLinkMTU);

		len += sizeof(*mtu);
	}

	/*
	 * add Source Link-layer Address option
	 */

	if (iface->AdvSourceLLAddress && iface->if_hwaddr_len != -1)
	{
		uint8_t *ucp;
		unsigned int i;

		ucp = (uint8_t *) (buff + len);
	
		*ucp++  = ND_OPT_SOURCE_LINKADDR;
		*ucp++  = (uint8_t) ((iface->if_hwaddr_len + 16 + 63) >> 6);

		len += 2 * sizeof(uint8_t);

		i = (iface->if_hwaddr_len + 7) >> 3;
		memcpy(buff + len, iface->if_hwaddr, i);
		len += i;
	}

	/*
	 * Mobile IPv6 ext: Advertisement Interval Option to support
	 * movement detection of mobile nodes
	 */

	if(iface->AdvIntervalOpt)
	{
		struct AdvInterval a_ival;
                uint32_t ival;
                if(iface->MaxRtrAdvInterval < Cautious_MaxRtrAdvInterval){
                       ival  = ((iface->MaxRtrAdvInterval +
                                 Cautious_MaxRtrAdvInterval_Leeway ) * 1000);

                }
                else {
                       ival  = (iface->MaxRtrAdvInterval * 1000);
                }
 		a_ival.type	= ND_OPT_RTR_ADV_INTERVAL;
		a_ival.length	= 1;
		a_ival.reserved	= 0;
		a_ival.adv_ival	= htonl(ival);

		memcpy(buff + len, &a_ival, sizeof(a_ival));
		len += sizeof(a_ival);
	}

	/*
	 * Mobile IPv6 ext: Home Agent Information Option to support
	 * Dynamic Home Agent Address Discovery
	 */

	if(iface->AdvHomeAgentInfo &&
	   (iface->AdvMobRtrSupportFlag || iface->HomeAgentPreference != 0 ||
	    iface->HomeAgentLifetime != iface->AdvDefaultLifetime))

	{
		struct HomeAgentInfo ha_info;
 		ha_info.type		= ND_OPT_HOME_AGENT_INFO;
		ha_info.length		= 1;
		ha_info.flags_reserved	=
			(iface->AdvMobRtrSupportFlag)?ND_OPT_HAI_FLAG_SUPPORT_MR:0;
		ha_info.preference	= htons(iface->HomeAgentPreference);
		ha_info.lifetime	= htons(iface->HomeAgentLifetime);

		memcpy(buff + len, &ha_info, sizeof(ha_info));
		len += sizeof(ha_info);
	}

  {
    /* add routing metric */
    struct AdvMetric metric;
    metric.type = ICMP_EXT_TYPE_BEACON;
    metric.length = 1;
    metric.metric = htons(0);
    metric.seqno = htons(routing_get_seqno());
    memset(metric.pad, 0, sizeof(metric.pad));

    memcpy(buff + len, &metric, sizeof(struct AdvMetric));
    len += sizeof(struct AdvMetric);
  }
	
	iov.iov_len  = len;
	iov.iov_base = (caddr_t) buff;
	
	memset(chdr, 0, sizeof(chdr));
	cmsg = (struct cmsghdr *) chdr;
	
	cmsg->cmsg_len   = CMSG_LEN(sizeof(struct in6_pktinfo));
	cmsg->cmsg_level = IPPROTO_IPV6;
	cmsg->cmsg_type  = IPV6_PKTINFO;
	
	pkt_info = (struct in6_pktinfo *)CMSG_DATA(cmsg);
	pkt_info->ipi6_ifindex = iface->if_index;
	memcpy(&pkt_info->ipi6_addr, &iface->if_addr, sizeof(struct in6_addr));

#ifdef HAVE_SIN6_SCOPE_ID
	if (IN6_IS_ADDR_LINKLOCAL(&addr.sin6_addr) ||
		IN6_IS_ADDR_MC_LINKLOCAL(&addr.sin6_addr))
			addr.sin6_scope_id = iface->if_index;
#endif

	memset(&mhdr, 0, sizeof(mhdr));
	mhdr.msg_name = (caddr_t)&addr;
	mhdr.msg_namelen = sizeof(struct sockaddr_in6);
	mhdr.msg_iov = &iov;
	mhdr.msg_iovlen = 1;
	mhdr.msg_control = (void *) cmsg;
	mhdr.msg_controllen = sizeof(chdr);

	err = sendmsg(sock, &mhdr, 0);
	
	if (err < 0) {
		if (!iface->IgnoreIfMissing || !(errno == EINVAL || errno == ENODEV))
			flog(LOG_WARNING, "sendmsg: %s", strerror(errno));
		else
			dlog(LOG_DEBUG, 3, "sendmsg: %s", strerror(errno));
	}
}
