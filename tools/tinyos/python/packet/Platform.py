#
# Copyright (c) 2006
#      The President and Fellows of Harvard College.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Author: Geoffrey Mainland <mainland@eecs.harvard.edu>
#
import re
import socket
import sys
import traceback

DEBUG = False

PLATFORMS = {"mica": ("avrmote", 1, 19200),
             "mica2dot": ("avrmote", 1, 19200),
             "mica2": ("avrmote", 1, 57600),
             "telos": ("telos", 2, 57600),
             "tmote": ("telos", 2, 57600),
             "micaz": ("avrmote", 3, 57600),
             "eyes": ("eyes", 4, 19200)}

ID_AVRMOTE = 1
ID_TELOS = 2
ID_MICAZ = 3
ID_EYES = 4

DEFAULT_BAUD = 19200

class UnknownPlatform(Exception):
    pass

def baud_from_name(name):
    try:
        return PLATFORMS[name][2]
    except:
        raise UnknownPlatform()

def default_factory():
    return factory_from_platform("avrmote")

def factory_from_name(name):
    try:
        return factory_from_platform(PLATFORMS[name][0])
    except:
        raise UnknownPlatform()

def factory_from_id(i):
    if i == ID_AVRMOTE:
        return factory_from_platform("avrmote")
    elif i == ID_TELOS:
        return factory_from_platform("telos")
    elif i == ID_MICAZ:
        return factory_from_platform("avrmote")
    else:
        raise UnknownPlatform()

def factory_from_platform(platform):
    try:
        mod = __import__("tinyos.packet.%s" % platform)
        return mod.packet.__dict__[platform].TOS_Msg
    except Exception, x:
        if DEBUG:
            print >>sys.stderr, x
            print >>sys.stderr, traceback.print_tb(sys.exc_info()[2])
        raise UnknownPlatform()
