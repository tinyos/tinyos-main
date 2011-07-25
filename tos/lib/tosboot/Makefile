# $Id: Makefile,v 1.8 2010-06-29 22:07:50 scipio Exp $

#
#
#
# Copyright (c) 2000-2005 The Regents of the University  of California.
# All rights reserved.
#
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions
 # are met:
 #
 # - Redistributions of source code must retain the above copyright
 #   notice, this list of conditions and the following disclaimer.
 # - Redistributions in binary form must reproduce the above copyright
 #   notice, this list of conditions and the following disclaimer in the
 #   documentation and/or other materials provided with the
 #   distribution.
 # - Neither the name of the copyright holders nor the names of
 #   its contributors may be used to endorse or promote products derived
 #   from this software without specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 # "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 # LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 # FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 # THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 # INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 # SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 # HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 # STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 # OF THE POSSIBILITY OF SUCH DAMAGE.
#
#

#
# @author Jonathan Hui <jwhui@cs.berkeley.edu>
#

COMPONENT=TosBootC
TINYOS_NP=

PFLAGS += -DNESC_BUILD_BINARY

# ifeq ($(MAKECMDGOALS),mica2)
#   CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
#   CFLAGS += -Wl,--section-start=.text=0x1f000
#   CFLAGS += -Iat45db -Iavr -Imica2 -Ilib
# endif

# ifeq ($(MAKECMDGOALS),mica2dot)
#   CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
#   CFLAGS += -Wl,--section-start=.text=0x1f000
#   CFLAGS += -Iat45db -Iavr -Imica2dot -Ilib
# endif

ifeq ($(MAKECMDGOALS),micaz)
  CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  CFLAGS += -Wl,--section-start=.text=0x1f000
  CFLAGS += -Iat45db -Iavr -Imicaz -Ilib
  CFLAGS += -I../net/Deluge
endif

ifeq ($(MAKECMDGOALS),iris)
  CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  CFLAGS += -Wl,--section-start=.text=0x1f000
  CFLAGS += -Iiris -Iat45db -Iavr -Imicaz -Ilib
  CFLAGS += -I../net/Deluge
endif

# ifeq ($(MAKECMDGOALS),telosa)
#   CFLAGS += -DTOSBOOT_START=0x1100 -DTOSBOOT_END=0x1a00
#   CFLAGS += -Iat45db -Imsp430 -Itelos -Ilib
#   POST_BUILD_EXTRA_DEPS += strip_iv
# endif

ifeq ($(MAKECMDGOALS),telosb)
  CFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4a00
  CFLAGS += -Imsp430 -Imsp430f1611 -Istm25p -Itelosb -Ilib
  CFLAGS += -I../net/Deluge
  POST_BUILD_EXTRA_DEPS += strip_iv
endif

ifeq ($(MAKECMDGOALS),epic)
  CFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4a00
  CFLAGS += -Imsp430 -Imsp430f1611 -Iepic -Ilib
  CFLAGS += -I../net/Deluge
  POST_BUILD_EXTRA_DEPS += strip_iv
endif

ifeq ($(MAKECMDGOALS),mulle)
  CFLAGS += -DTOSBOOT_START=0xe0000 -DTOSBOOT_END=0xeffff
  CFLAGS += -Iat45db -Imulle -Im16c60 -Im16c60/62p -Ilib
  CFLAGS += -I../net/Deluge -I../net/Deluge/extra/mulle
  CFLAGS += -I../net/Deluge/extra/m16c60
  CFLAGS += -I../net/Deluge/extra/m16c60/62p
endif

ifeq ($(MAKECMDGOALS),tinynode)
  CFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4a00
  CFLAGS += -Itinynode -Imsp430 -Imsp430f1611 -Iat45db -Ilib
  CFLAGS += -I../net/Deluge
  POST_BUILD_EXTRA_DEPS += strip_iv 
endif



strip_iv: FORCE
	@echo "    removing interrupt vector from binary"
	msp430-objcopy -j .text -j .data -O ihex $(BUILDDIR)/main.exe $(BUILDDIR)/main.ihex

include $(MAKERULES)
