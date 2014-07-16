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

$(warning $(MAKECMDGOALS))
# ifeq ($(MAKECMDGOALS),mica2)
#   PFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
#   PFLAGS += -Wl,--section-start=.text=0x1f000
#   PFLAGS += -Iat45db -Iavr -Imica2 -Ilib
# endif

# ifeq ($(MAKECMDGOALS),mica2dot)
#   PFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
#   PFLAGS += -Wl,--section-start=.text=0x1f000
#   PFLAGS += -Iat45db -Iavr -Imica2dot -Ilib
# endif

ifeq ($(MAKECMDGOALS),micaz)
  PFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  PFLAGS += -Wl,--section-start=.text=0x1f000
  PFLAGS += -Iat45db -Iavr -Imicaz -Ilib
  PFLAGS += -I../net/Deluge
endif

ifeq ($(MAKECMDGOALS),iris)
  PFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  PFLAGS += -Wl,--section-start=.text=0x1f000
  PFLAGS += -Iiris -Iat45db -Iavr -Imicaz -Ilib
  PFLAGS += -I../net/Deluge
endif

# ifeq ($(MAKECMDGOALS),telosa)
#   PFLAGS += -DTOSBOOT_START=0x1100 -DTOSBOOT_END=0x1a00
#   PFLAGS += -Iat45db -Imsp430 -Itelos -Ilib
#   BUILD_DEPS += strip_iv
# endif

ifeq ($(MAKECMDGOALS),telosb)
  PFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4a00
  PFLAGS += -Imsp430 -Imsp430f1611 -Istm25p -Itelosb -Ilib
  PFLAGS += -I../net/Deluge
  BUILD_DEPS += strip_iv
endif

ifeq ($(MAKECMDGOALS),epic)
  PFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4a00
  PFLAGS += -Imsp430 -Imsp430f1611 -Iepic -Ilib
  PFLAGS += -I../net/Deluge
  BUILD_DEPS += strip_iv
endif

ifeq ($(MAKECMDGOALS),mulle)
  PFLAGS += -DTOSBOOT_START=0xe0000 -DTOSBOOT_END=0xeffff
  PFLAGS += -Iat45db -Imulle -Im16c60 -Im16c60/62p -Ilib
  PFLAGS += -I../net/Deluge -I../net/Deluge/extra/mulle
  PFLAGS += -I../net/Deluge/extra/m16c60
  PFLAGS += -I../net/Deluge/extra/m16c60/62p
endif

ifeq ($(MAKECMDGOALS),tinynode)
  PFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4a00
  PFLAGS += -Itinynode -Imsp430 -Imsp430f1611 -Iat45db -Ilib
  PFLAGS += -I../net/Deluge
  BUILD_DEPS += strip_iv
endif

strip_iv: tinyos_image FORCE
	@echo -e '$(INFO_STRING) removing interrupt vector from binary'
	msp430-objcopy -j .text -j .data -O ihex $(TOSMAKE_BUILD_DIR)/main.exe $(TOSMAKE_BUILD_DIR)/main.ihex

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
