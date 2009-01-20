/*
 *   $Id: scanner.l,v 1.1 2009-01-20 00:28:15 sdhsdh Exp $
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
#include <gram.h>

extern char *conf_file;

int num_lines = 1;
%}

digit		[0-9]
number		({digit})+
snum		-?({digit})+
decimal		({number}"."{number})
hexdigit	([a-f]|[A-F]|[0-9])
addr1		{hexdigit}{1,4}":"({hexdigit}{1,4}":")*(":"{hexdigit}{1,4})+
addr2		{hexdigit}{1,4}(":"{hexdigit}{1,4})*"::"
addr3		({hexdigit}{1,4}":"){7}{hexdigit}{1,4}
addr		({addr1}|{addr2}|{addr3}|"::")
whitespace	([ \t])+
string		[a-z]([a-z]|{digit}|_)*([:.]{digit}+)?
%%

#.*$			{/* ignore comments */}
\n			{num_lines++;}
{whitespace}		{}

interface		{ return T_INTERFACE; }
prefix			{ return T_PREFIX; }
route			{ return T_ROUTE; }
RDNSS			{ return T_RDNSS; }

IgnoreIfMissing		{ return T_IgnoreIfMissing; }
AdvSendAdvert		{ return T_AdvSendAdvert; }
MaxRtrAdvInterval	{ return T_MaxRtrAdvInterval; }
MinRtrAdvInterval	{ return T_MinRtrAdvInterval; }
AdvManagedFlag		{ return T_AdvManagedFlag; }
AdvOtherConfigFlag	{ return T_AdvOtherConfigFlag; }
AdvLinkMTU		{ return T_AdvLinkMTU; }
AdvReachableTime	{ return T_AdvReachableTime; }
AdvRetransTimer		{ return T_AdvRetransTimer; }
AdvCurHopLimit		{ return T_AdvCurHopLimit; }
AdvDefaultLifetime	{ return T_AdvDefaultLifetime; }
AdvDefaultPreference	{ return T_AdvDefaultPreference; }
AdvSourceLLAddress	{ return T_AdvSourceLLAddress; }

AdvOnLink		{ return T_AdvOnLink; }
AdvAutonomous		{ return T_AdvAutonomous; }
AdvValidLifetime	{ return T_AdvValidLifetime; }
AdvPreferredLifetime	{ return T_AdvPreferredLifetime; }

AdvRouterAddr		{ return T_AdvRouterAddr; }
AdvHomeAgentFlag	{ return T_AdvHomeAgentFlag; }
AdvIntervalOpt		{ return T_AdvIntervalOpt; }
AdvHomeAgentInfo	{ return T_AdvHomeAgentInfo; }
UnicastOnly		{ return T_UnicastOnly; }

Base6to4Interface	{ return T_Base6to4Interface; }

HomeAgentPreference	{ return T_HomeAgentPreference; }
HomeAgentLifetime	{ return T_HomeAgentLifetime; }

AdvRoutePreference	{ return T_AdvRoutePreference; }
AdvRouteLifetime	{ return T_AdvRouteLifetime; }

AdvRDNSSPreference 	{ return T_AdvRDNSSPreference; }
AdvRDNSSOpen		{ return T_AdvRDNSSOpenFlag; }
AdvRDNSSLifetime	{ return T_AdvRDNSSLifetime; }

MinDelayBetweenRAs      { return T_MinDelayBetweenRAs; }

AdvMobRtrSupportFlag	{ return T_AdvMobRtrSupportFlag; }

{addr}		{
			static struct in6_addr addr;
			int i;
				
			i = inet_pton(AF_INET6, yytext, &addr);

			dlog(LOG_DEBUG, 4, "inet_pton returned %d", i);

			/* BSD API draft and NRL's code don't aggree on
			 * this. the draft specifies a return value of 1 on 
			 * success, NRL's code returns the address length in 
			 * bytes on success (16 for an IPv6 address)
			 */
			if (i < 1) {
				flog(LOG_ERR, "invalid address in %s, line %d", conf_file,
					num_lines);
				return T_BAD_TOKEN;
			}

			yylval.addr = &addr;
			return IPV6ADDR;
		}

{number}	{
			unsigned long lnum;
			char *endp;
			lnum = strtoul(yytext, &endp, 10);
			if (*yytext == '\0' || *endp != '\0')
				return T_BAD_TOKEN;
			if (lnum > 0xFFFFFFFFUL)
				return T_BAD_TOKEN;	/* XXX */
			yylval.num = lnum;
			return NUMBER;
		}

{snum}		{ yylval.snum = atoi(yytext); return SIGNEDNUMBER; }

{decimal}	{ yylval.dec = atof(yytext); return DECIMAL; }

infinity	{ return INFINITY; }

on			{ yylval.bool = 1; return SWITCH; }

off			{ yylval.bool = 0; return SWITCH; }

low		{ yylval.snum = -1; return SIGNEDNUMBER; }

medium		{ yylval.snum = 0; return SIGNEDNUMBER; }

high		{ yylval.snum = 1; return SIGNEDNUMBER; }

{string}	{
			static char name[IFNAMSIZ];
				
			strncpy(name, yytext, IFNAMSIZ-1);
			name[IFNAMSIZ-1] = '\0';
			yylval.str = name;
			return STRING;
		}

"{"|"}"|";"|"/"	{ return *yytext; }

.		{ return T_BAD_TOKEN; }
%%
