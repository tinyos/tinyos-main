/*
 *   $Id: gram.y,v 1.2 2009-08-09 23:36:05 sdhsdh Exp $
 *
 *   Authors:
 *    Pedro Roque		<roque@di.fc.ul.pt>
 *    Lars Fenneberg		<lf@elemental.net>	 
 *
 *   This software is Copyright 1996-2000 by the above mentioned author(s), 
 *   All Rights Reserved.
 *
 *   The license which is distributed with this software in the file COPYRIGHT
 *   applies to this software. If your distribution is missing this file, you
 *   may request it from <pekkas@netcore.fi>.
 *
 */
%{
#include <config.h>
#include <includes.h>
#include <radvd.h>
#include <defaults.h>

extern struct Interface *IfaceList;
struct Interface *iface = NULL;
struct AdvPrefix *prefix = NULL;
struct AdvRoute *route = NULL;
struct AdvRDNSS *rdnss = NULL;

extern char *conf_file;
extern int num_lines;
extern char *yytext;
extern int sock;

static void cleanup(void);
static void yyerror(char *msg);

#if 0 /* no longer necessary? */
#ifndef HAVE_IN6_ADDR_S6_ADDR
# ifdef __FreeBSD__
#  define s6_addr32 __u6_addr.__u6_addr32
#  define s6_addr16 __u6_addr.__u6_addr16
# endif
#endif
#endif

#define ABORT	do { cleanup(); YYABORT; } while (0);

%}

%token		T_INTERFACE
%token		T_PREFIX
%token		T_ROUTE
%token		T_RDNSS

%token	<str>	STRING
%token	<num>	NUMBER
%token	<snum>	SIGNEDNUMBER
%token	<dec>	DECIMAL
%token	<bool>	SWITCH
%token	<addr>	IPV6ADDR
%token 		INFINITY

%token		T_IgnoreIfMissing
%token		T_AdvSendAdvert
%token		T_MaxRtrAdvInterval
%token		T_MinRtrAdvInterval
%token		T_MinDelayBetweenRAs
%token		T_AdvManagedFlag
%token		T_AdvOtherConfigFlag
%token		T_AdvLinkMTU
%token		T_AdvReachableTime
%token		T_AdvRetransTimer
%token		T_AdvCurHopLimit
%token		T_AdvDefaultLifetime
%token		T_AdvDefaultPreference
%token		T_AdvSourceLLAddress

%token		T_AdvOnLink
%token		T_AdvAutonomous
%token		T_AdvValidLifetime
%token		T_AdvPreferredLifetime

%token		T_AdvRouterAddr
%token		T_AdvHomeAgentFlag
%token		T_AdvIntervalOpt
%token		T_AdvHomeAgentInfo

%token		T_Base6to4Interface
%token		T_UnicastOnly

%token		T_HomeAgentPreference
%token		T_HomeAgentLifetime

%token		T_AdvRoutePreference
%token		T_AdvRouteLifetime

%token		T_AdvRDNSSPreference
%token		T_AdvRDNSSOpenFlag
%token		T_AdvRDNSSLifetime

%token		T_AdvMobRtrSupportFlag

%token		T_BAD_TOKEN

%type	<str>	name
%type	<pinfo> optional_prefixlist prefixdef prefixlist
%type	<rinfo>	optional_routelist routedef routelist
%type	<rdnssinfo> optional_rdnsslist rdnssdef rdnsslist
%type   <num>	number_or_infinity

%union {
	unsigned int		num;
	int			snum;
	double			dec;
	int			bool;
	struct in6_addr		*addr;
	char			*str;
	struct AdvPrefix	*pinfo;
	struct AdvRoute		*rinfo;
	struct AdvRDNSS		*rdnssinfo;
};

%%

grammar		: grammar ifacedef
		| ifacedef
		;

ifacedef	: ifacehead '{' ifaceparams  '}' ';'
		{
			struct Interface *iface2;

			iface2 = IfaceList;
			while (iface2)
			{
				if (!strcmp(iface2->Name, iface->Name))
				{
					flog(LOG_ERR, "duplicate interface "
						"definition for %s", iface->Name);
					ABORT;
				}
				iface2 = iface2->next;
			}			

			if (check_device(sock, iface) < 0) {
				if (iface->IgnoreIfMissing) {
					dlog(LOG_DEBUG, 4, "interface %s did not exist, ignoring the interface", iface->Name);
					goto skip_interface;
				}
				else {
					flog(LOG_ERR, "interface %s does not exist", iface->Name);
					ABORT;
				}
			}
			if (setup_deviceinfo(sock, iface) < 0)
				ABORT;
			if (check_iface(iface) < 0)
				ABORT;
			if (setup_linklocal_addr(sock, iface) < 0)
				ABORT;
			if (setup_allrouters_membership(sock, iface) < 0)
				ABORT;

			iface->next = IfaceList;
			IfaceList = iface;

			dlog(LOG_DEBUG, 4, "interface definition for %s is ok", iface->Name);

skip_interface:
			iface = NULL;
		};

ifacehead	: T_INTERFACE name
		{
			iface = malloc(sizeof(struct Interface));

			if (iface == NULL) {
				flog(LOG_CRIT, "malloc failed: %s", strerror(errno));
				ABORT;
			}

			iface_init_defaults(iface);
			strncpy(iface->Name, $2, IFNAMSIZ-1);
			iface->Name[IFNAMSIZ-1] = '\0';
		}
		;
	
name		: STRING
		{
			/* check vality */
			$$ = $1;
		}
		;

ifaceparams	: optional_ifacevlist optional_prefixlist optional_routelist optional_rdnsslist
		{
			iface->AdvPrefixList = $2;
			iface->AdvRouteList = $3;
			iface->AdvRDNSSList = $4;
		}
		;

optional_ifacevlist: /* empty */
		   | ifacevlist
		   ;

optional_prefixlist: /* empty */
		{
			$$ = NULL;
		}
		| prefixlist
		;

optional_routelist: /* empty */
		{
			$$ = NULL;
		}
		| routelist
		;
		
optional_rdnsslist: /* empty */
		{
			$$ = NULL;
		}
		| rdnsslist
		;

ifacevlist	: ifacevlist ifaceval
		| ifaceval
		;

ifaceval	: T_MinRtrAdvInterval NUMBER ';'
		{
			iface->MinRtrAdvInterval = $2;
		}
		| T_MaxRtrAdvInterval NUMBER ';'
		{
			iface->MaxRtrAdvInterval = $2;
		}
		| T_MinDelayBetweenRAs NUMBER ';'
		{
			iface->MinDelayBetweenRAs = $2;
		}
		| T_MinRtrAdvInterval DECIMAL ';'
		{
			iface->MinRtrAdvInterval = $2;
		}
		| T_MaxRtrAdvInterval DECIMAL ';'
		{
			iface->MaxRtrAdvInterval = $2;
		}
		| T_MinDelayBetweenRAs DECIMAL ';'
		{
			iface->MinDelayBetweenRAs = $2;
		}
		| T_IgnoreIfMissing SWITCH ';'
		{
			iface->IgnoreIfMissing = $2;
		}
		| T_AdvSendAdvert SWITCH ';'
		{
			iface->AdvSendAdvert = $2;
		}
		| T_AdvManagedFlag SWITCH ';'
		{
			iface->AdvManagedFlag = $2;
		}
		| T_AdvOtherConfigFlag SWITCH ';'
		{
			iface->AdvOtherConfigFlag = $2;
		}
		| T_AdvLinkMTU NUMBER ';'
		{
			iface->AdvLinkMTU = $2;
		}
		| T_AdvReachableTime NUMBER ';'
		{
			iface->AdvReachableTime = $2;
		}
		| T_AdvRetransTimer NUMBER ';'
		{
			iface->AdvRetransTimer = $2;
		}
		| T_AdvDefaultLifetime NUMBER ';'
		{
			iface->AdvDefaultLifetime = $2;
		}
		| T_AdvDefaultPreference SIGNEDNUMBER ';'
		{
			iface->AdvDefaultPreference = $2;
		}
		| T_AdvCurHopLimit NUMBER ';'
		{
			iface->AdvCurHopLimit = $2;
		}
		| T_AdvSourceLLAddress SWITCH ';'
		{
			iface->AdvSourceLLAddress = $2;
		}
		| T_AdvIntervalOpt SWITCH ';'
		{
			iface->AdvIntervalOpt = $2;
		}
		| T_AdvHomeAgentInfo SWITCH ';'
		{
			iface->AdvHomeAgentInfo = $2;
		}
		| T_AdvHomeAgentFlag SWITCH ';'
		{
			iface->AdvHomeAgentFlag = $2;
		}
		| T_HomeAgentPreference NUMBER ';'
		{
			iface->HomeAgentPreference = $2;
		}
		| T_HomeAgentLifetime NUMBER ';'
		{
			iface->HomeAgentLifetime = $2;
		}
		| T_UnicastOnly SWITCH ';'
		{
			iface->UnicastOnly = $2;
		}
		| T_AdvMobRtrSupportFlag SWITCH ';'
		{
			iface->AdvMobRtrSupportFlag = $2;
		}
		;
		
prefixlist	: prefixdef
		{
			$$ = $1;
		}
		| prefixlist prefixdef
		{
			$2->next = $1;
			$$ = $2;
		}
		;

prefixdef	: prefixhead '{' optional_prefixplist '}' ';'
		{
			unsigned int dst;

			if (prefix->AdvPreferredLifetime >
			    prefix->AdvValidLifetime)
			{
				flog(LOG_ERR, "AdvValidLifeTime must be "
					"greater than AdvPreferredLifetime in %s, line %d", 
					conf_file, num_lines);
				ABORT;
			}

			if( prefix->if6to4[0] )
			{
				if (get_v4addr(prefix->if6to4, &dst) < 0)
				{
					flog(LOG_ERR, "interface %s has no IPv4 addresses, disabling 6to4 prefix", prefix->if6to4 );
					prefix->enabled = 0;
				} else
				{
					*((uint16_t *)(prefix->Prefix.s6_addr)) = htons(0x2002);
					memcpy( prefix->Prefix.s6_addr + 2, &dst, sizeof( dst ) );
				}
			}

			$$ = prefix;
			prefix = NULL;
		}
		;

prefixhead	: T_PREFIX IPV6ADDR '/' NUMBER
		{
			prefix = malloc(sizeof(struct AdvPrefix));
			
			if (prefix == NULL) {
				flog(LOG_CRIT, "malloc failed: %s", strerror(errno));
				ABORT;
			}

			prefix_init_defaults(prefix);

			if ($4 > MAX_PrefixLen)
			{
				flog(LOG_ERR, "invalid prefix length in %s, line %d", conf_file, num_lines);
				ABORT;
			}

			prefix->PrefixLen = $4;

			memcpy(&prefix->Prefix, $2, sizeof(struct in6_addr));
		}
		;

optional_prefixplist: /* empty */
		| prefixplist 
		;

prefixplist	: prefixplist prefixparms
		| prefixparms
		;

prefixparms	: T_AdvOnLink SWITCH ';'
		{
			prefix->AdvOnLinkFlag = $2;
		}
		| T_AdvAutonomous SWITCH ';'
		{
			prefix->AdvAutonomousFlag = $2;
		}
		| T_AdvRouterAddr SWITCH ';'
		{
			prefix->AdvRouterAddr = $2;
		}
		| T_AdvValidLifetime number_or_infinity ';'
		{
			prefix->AdvValidLifetime = $2;
		}
		| T_AdvPreferredLifetime number_or_infinity ';'
		{
			prefix->AdvPreferredLifetime = $2;
		}
		| T_Base6to4Interface name ';'
		{
			dlog(LOG_DEBUG, 4, "using interface %s for 6to4", $2);
			strncpy(prefix->if6to4, $2, IFNAMSIZ-1);
			prefix->if6to4[IFNAMSIZ-1] = '\0';
		}
		;

routelist	: routedef
		{
			$$ = $1;
		}
		| routelist routedef
		{
			$2->next = $1;
			$$ = $2;
		}
		;

routedef	: routehead '{' optional_routeplist '}' ';'
		{
			$$ = route;
			route = NULL;
		}
		;


routehead	: T_ROUTE IPV6ADDR '/' NUMBER
		{
			route = malloc(sizeof(struct AdvRoute));
			
			if (route == NULL) {
				flog(LOG_CRIT, "malloc failed: %s", strerror(errno));
				ABORT;
			}

			route_init_defaults(route, iface);

			if ($4 > MAX_PrefixLen)
			{
				flog(LOG_ERR, "invalid route prefix length in %s, line %d", conf_file, num_lines);
				ABORT;
			}

			route->PrefixLen = $4;

			memcpy(&route->Prefix, $2, sizeof(struct in6_addr));
		}
		;


optional_routeplist: /* empty */
		| routeplist 
		;

routeplist	: routeplist routeparms
		| routeparms
		;


routeparms	: T_AdvRoutePreference SIGNEDNUMBER ';'
		{
			route->AdvRoutePreference = $2;
		}
		| T_AdvRouteLifetime number_or_infinity ';'
		{
			route->AdvRouteLifetime = $2;
		}
		;
		
rdnsslist	: rdnssdef
		{
			$$ = $1;
		}
		| rdnsslist rdnssdef
		{
			$2->next = $1;
			$$ = $2;
		}
		;
		
rdnssdef	: rdnsshead '{' optional_rdnssplist '}' ';'
		{
			$$ = rdnss;
			rdnss = NULL;
		}
		;

rdnssaddrs	: rdnssaddrs rdnssaddr
		| rdnssaddr
		;

rdnssaddr	: IPV6ADDR
		{
			if (!rdnss) {
				/* first IP found */
				rdnss = malloc(sizeof(struct AdvRDNSS));
				
				if (rdnss == NULL) {
					flog(LOG_CRIT, "malloc failed: %s", strerror(errno));
					ABORT;
				}

				rdnss_init_defaults(rdnss, iface);
			}
			
			switch (rdnss->AdvRDNSSNumber) {
				case 0:
					memcpy(&rdnss->AdvRDNSSAddr1, $1, sizeof(struct in6_addr));
					rdnss->AdvRDNSSNumber++;
					break;
				case 1:
					memcpy(&rdnss->AdvRDNSSAddr2, $1, sizeof(struct in6_addr));
					rdnss->AdvRDNSSNumber++;
					break;
				case 2:
					memcpy(&rdnss->AdvRDNSSAddr3, $1, sizeof(struct in6_addr));
					rdnss->AdvRDNSSNumber++;
					break;
				default:
					flog(LOG_CRIT, "Too many addresses in RDNSS section");
					ABORT;
			}
			
		}
		;
		
rdnsshead	: T_RDNSS rdnssaddrs
		{
			if (!rdnss) {
				flog(LOG_CRIT, "No address specified in RDNSS section");
				ABORT;
			}
		}
		;
		
optional_rdnssplist: /* empty */
		| rdnssplist 
		;
		
rdnssplist	: rdnssplist rdnssparms
		| rdnssparms
		;


rdnssparms	: T_AdvRDNSSPreference NUMBER ';'
		{
			rdnss->AdvRDNSSPreference = $2;
		}
		| T_AdvRDNSSOpenFlag SWITCH ';'
		{
			rdnss->AdvRDNSSOpenFlag = $2;
		}
		| T_AdvRDNSSLifetime number_or_infinity ';'
		{
			if ($2 < iface->MaxRtrAdvInterval && $2 != 0) {
				flog(LOG_ERR, "AdvRDNSSLifetime must be at least MaxRtrAdvInterval");
				ABORT;
			}
			if ($2 > 2*(iface->MaxRtrAdvInterval))
				flog(LOG_WARNING, "Warning: AdvRDNSSLifetime <= 2*MaxRtrAdvInterval would allow stale DNS servers to be deleted faster");

			rdnss->AdvRDNSSLifetime = $2;
		}
		;

number_or_infinity      : NUMBER
                        {
                                $$ = $1; 
                        }
                        | INFINITY
                        {
                                $$ = (uint32_t)~0;
                        }
                        ;

%%

static
void cleanup(void)
{
	if (iface)
		free(iface);
	
	if (prefix)
		free(prefix);

	if (route)
		free(route);

	if (rdnss)
		free(rdnss);
}

static void
yyerror(char *msg)
{
	cleanup();
	flog(LOG_ERR, "%s in %s, line %d: %s", msg, conf_file, num_lines, yytext);
}
