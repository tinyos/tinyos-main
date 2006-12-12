#
# $Id: Makefile.am,v 1.4 2006-12-12 18:23:01 vlahan Exp $
#
# uisp - The Micro In-System Programmer for Atmel AVR microcontrollers.
# Copyright (C) 2002  Theodore A. Roth
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Makefile.am -- Process this file with automake to produce Makefile.in
#

MAINTAINERCLEANFILES = Makefile.in

#SUBDIRS              = 
#DIST_SUBDIRS         = 

#EXTRA_DIST           = 

# Turn on all warnings and consider them errors. This kinda forces you to have
# to use gcc, but I'd rather have all warnings eliminated.
# There's a header file macro causing warnings on cygwin => -Werror removed

AM_CXXFLAGS          = -Wall

bin_PROGRAMS         = uisp
uisp_SOURCES         = \
	Avr.C              \
	Avr.h              \
	AvrAtmel.C         \
	AvrAtmel.h         \
	AvrDummy.C         \
	AvrDummy.h         \
	AvrStargate.C      \
	AvrStargate.h      \
	DAPA.C             \
	DAPA.h             \
	Error.h            \
	Global.h           \
	Main.C             \
	MotIntl.C          \
	MotIntl.h          \
	SASA.C             \
	SASA.h	           \
	Serial.C           \
	Serial.h           \
	Stk500.C           \
	Stk500.h           \
	Terminal.C         \
	Terminal.h         \
	cygwinp.C          \
	cygwinp.h          \
	parport.h          \
	ppdev.h            \
	timeradd.h
