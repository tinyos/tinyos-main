/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     T_INTERFACE = 258,
     T_PREFIX = 259,
     T_ROUTE = 260,
     T_RDNSS = 261,
     STRING = 262,
     NUMBER = 263,
     SIGNEDNUMBER = 264,
     DECIMAL = 265,
     SWITCH = 266,
     IPV6ADDR = 267,
     INFINITY = 268,
     T_IgnoreIfMissing = 269,
     T_AdvSendAdvert = 270,
     T_MaxRtrAdvInterval = 271,
     T_MinRtrAdvInterval = 272,
     T_MinDelayBetweenRAs = 273,
     T_AdvManagedFlag = 274,
     T_AdvOtherConfigFlag = 275,
     T_AdvLinkMTU = 276,
     T_AdvReachableTime = 277,
     T_AdvRetransTimer = 278,
     T_AdvCurHopLimit = 279,
     T_AdvDefaultLifetime = 280,
     T_AdvDefaultPreference = 281,
     T_AdvSourceLLAddress = 282,
     T_AdvOnLink = 283,
     T_AdvAutonomous = 284,
     T_AdvValidLifetime = 285,
     T_AdvPreferredLifetime = 286,
     T_AdvRouterAddr = 287,
     T_AdvHomeAgentFlag = 288,
     T_AdvIntervalOpt = 289,
     T_AdvHomeAgentInfo = 290,
     T_Base6to4Interface = 291,
     T_UnicastOnly = 292,
     T_HomeAgentPreference = 293,
     T_HomeAgentLifetime = 294,
     T_AdvRoutePreference = 295,
     T_AdvRouteLifetime = 296,
     T_AdvRDNSSPreference = 297,
     T_AdvRDNSSOpenFlag = 298,
     T_AdvRDNSSLifetime = 299,
     T_AdvMobRtrSupportFlag = 300,
     T_BAD_TOKEN = 301
   };
#endif
/* Tokens.  */
#define T_INTERFACE 258
#define T_PREFIX 259
#define T_ROUTE 260
#define T_RDNSS 261
#define STRING 262
#define NUMBER 263
#define SIGNEDNUMBER 264
#define DECIMAL 265
#define SWITCH 266
#define IPV6ADDR 267
#define INFINITY 268
#define T_IgnoreIfMissing 269
#define T_AdvSendAdvert 270
#define T_MaxRtrAdvInterval 271
#define T_MinRtrAdvInterval 272
#define T_MinDelayBetweenRAs 273
#define T_AdvManagedFlag 274
#define T_AdvOtherConfigFlag 275
#define T_AdvLinkMTU 276
#define T_AdvReachableTime 277
#define T_AdvRetransTimer 278
#define T_AdvCurHopLimit 279
#define T_AdvDefaultLifetime 280
#define T_AdvDefaultPreference 281
#define T_AdvSourceLLAddress 282
#define T_AdvOnLink 283
#define T_AdvAutonomous 284
#define T_AdvValidLifetime 285
#define T_AdvPreferredLifetime 286
#define T_AdvRouterAddr 287
#define T_AdvHomeAgentFlag 288
#define T_AdvIntervalOpt 289
#define T_AdvHomeAgentInfo 290
#define T_Base6to4Interface 291
#define T_UnicastOnly 292
#define T_HomeAgentPreference 293
#define T_HomeAgentLifetime 294
#define T_AdvRoutePreference 295
#define T_AdvRouteLifetime 296
#define T_AdvRDNSSPreference 297
#define T_AdvRDNSSOpenFlag 298
#define T_AdvRDNSSLifetime 299
#define T_AdvMobRtrSupportFlag 300
#define T_BAD_TOKEN 301




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 110 "gram.y"
{
	unsigned int		num;
	int			snum;
	double			dec;
	int			bool;
	struct in6_addr		*addr;
	char			*str;
	struct AdvPrefix	*pinfo;
	struct AdvRoute		*rinfo;
	struct AdvRDNSS		*rdnssinfo;
}
/* Line 1489 of yacc.c.  */
#line 153 "y.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

