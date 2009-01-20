/*
 *   $Id: radvd.h,v 1.1 2009-01-20 00:28:15 sdhsdh Exp $
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

#ifndef RADV_H
#define RADV_H

#include <config.h>
#include <includes.h>
#include <defaults.h>

#define CONTACT_EMAIL	"Pekka Savola <pekkas@netcore.fi>"

/* for log.c */
#define	L_NONE		0
#define L_SYSLOG	1
#define L_STDERR	2
#define L_STDERR_SYSLOG	3
#define L_LOGFILE	4

#define LOG_TIME_FORMAT "%b %d %H:%M:%S"

struct timer_lst {
	struct timeval		expires;
	void			(*handler)(void *);
	void *			data;
	struct timer_lst	*next;
	struct timer_lst	*prev;	
};

#define min(a,b)	(((a) < (b)) ? (a) : (b))

struct AdvPrefix;

#define HWADDR_MAX 16

struct Interface {
	char			Name[IFNAMSIZ];	/* interface name */

	struct in6_addr		if_addr;
	unsigned int		if_index;

	uint8_t			init_racount;	/* Initial RAs */

	uint8_t			if_hwaddr[HWADDR_MAX];
	int			if_hwaddr_len;
	int			if_prefix_len;
	int			if_maxmtu;

	int			IgnoreIfMissing;
	int			AdvSendAdvert;
	double			MaxRtrAdvInterval;
	double			MinRtrAdvInterval;
	double			MinDelayBetweenRAs;
	int			AdvManagedFlag;
	int			AdvOtherConfigFlag;
	uint32_t		AdvLinkMTU;
	uint32_t		AdvReachableTime;
	uint32_t		AdvRetransTimer;
	uint8_t			AdvCurHopLimit;
	int32_t			AdvDefaultLifetime;   /* XXX: really uint16_t but we need to use -1 */
	int			AdvDefaultPreference;
	int			AdvSourceLLAddress;
	int			UnicastOnly;

	/* Mobile IPv6 extensions */
	int			AdvIntervalOpt;
	int			AdvHomeAgentInfo;
	int			AdvHomeAgentFlag;
	uint16_t		HomeAgentPreference;
	int32_t			HomeAgentLifetime;    /* XXX: really uint16_t but we need to use -1 */

	/* NEMO extensions */
	int			AdvMobRtrSupportFlag;

	struct AdvPrefix	*AdvPrefixList;
	struct AdvRoute		*AdvRouteList;
	struct AdvRDNSS		*AdvRDNSSList;
	struct timer_lst	tm;
	time_t			last_multicast_sec;
	suseconds_t		last_multicast_usec;

	/* Info whether this interface has failed in the past (and may need to be reinitialized) */
	int			HasFailed;

	struct Interface	*next;
};

struct AdvPrefix {
	struct in6_addr		Prefix;
	uint8_t			PrefixLen;
	
	int			AdvOnLinkFlag;
	int			AdvAutonomousFlag;
	uint32_t		AdvValidLifetime;
	uint32_t		AdvPreferredLifetime;

	/* Mobile IPv6 extensions */
	int             	AdvRouterAddr;

	/* 6to4 extensions */
	char			if6to4[IFNAMSIZ];
	int			enabled;

	struct AdvPrefix	*next;
};

/* More-Specific Routes extensions */

struct AdvRoute {
	struct in6_addr		Prefix;
	uint8_t			PrefixLen;
	
	int			AdvRoutePreference;
	uint32_t		AdvRouteLifetime;

	struct AdvRoute		*next;
};

/* Option for DNS configuration */
struct AdvRDNSS {
	int 			AdvRDNSSNumber;
	uint8_t			AdvRDNSSPreference;
	int 			AdvRDNSSOpenFlag;
	uint32_t		AdvRDNSSLifetime;
	struct in6_addr		AdvRDNSSAddr1;
	struct in6_addr		AdvRDNSSAddr2;
	struct in6_addr		AdvRDNSSAddr3;
	
	struct AdvRDNSS 	*next; 
};

/* Mobile IPv6 extensions */

struct AdvInterval {
	uint8_t			type;
	uint8_t			length;
	uint16_t		reserved;
	uint32_t		adv_ival;
};

struct HomeAgentInfo {
	uint8_t			type;
	uint8_t			length;
	uint16_t		flags_reserved;
	uint16_t		preference;
	uint16_t		lifetime;
};	


/* gram.y */
int yyparse(void);

/* scanner.l */
int yylex(void);

/* radvd.c */
int check_ip6_forwarding(void);
void reload_config(void);

/* timer.c */
void set_timer(struct timer_lst *tm, double);
void clear_timer(struct timer_lst *tm);
void init_timer(struct timer_lst *, void (*)(void *), void *); 

/* log.c */
int log_open(int, char *, char*, int);
void flog(int, char *, ...);
void dlog(int, int, char *, ...);
int log_close(void);
int log_reopen(void);
void set_debuglevel(int);
int get_debuglevel(void);

/* device.c */
int setup_deviceinfo(int, struct Interface *);
int check_device(int, struct Interface *);
int setup_linklocal_addr(int, struct Interface *);
int setup_allrouters_membership(int, struct Interface *);
int check_allrouters_membership(int, struct Interface *);
int get_v4addr(const char *, unsigned int *);
int set_interface_linkmtu(const char *, uint32_t);
int set_interface_curhlim(const char *, uint8_t);
int set_interface_reachtime(const char *, uint32_t);
int set_interface_retranstimer(const char *, uint32_t);

/* interface.c */
void iface_init_defaults(struct Interface *);
void prefix_init_defaults(struct AdvPrefix *);
void route_init_defaults(struct AdvRoute *, struct Interface *);
void rdnss_init_defaults(struct AdvRDNSS *, struct Interface *);
int check_iface(struct Interface *);

/* socket.c */
int open_icmpv6_socket(void);

/* send.c */
void send_ra(int, struct Interface *iface, struct in6_addr *dest);

/* process.c */
void process(int sock, struct Interface *, unsigned char *, int,
	struct sockaddr_in6 *, struct in6_pktinfo *, int);

/* recv.c */
int recv_rs_ra(int, unsigned char *, struct sockaddr_in6 *, struct in6_pktinfo **, int *);

/* util.c */
void mdelay(double);
double rand_between(double, double);
void print_addr(struct in6_addr *, char *);
int check_rdnss_presence(struct AdvRDNSS *, struct in6_addr *);

#endif
