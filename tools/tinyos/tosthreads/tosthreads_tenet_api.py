#!/usr/bin/python

# Copyright (c) 2008 Johns Hopkins University.
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written
# agreement is hereby granted, provided that the above copyright
# notice, the (updated) modification history and the author appear in
# all copies of this source code.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
# OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

# @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
# @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

import sys, subprocess
import struct


# ===== STEP 0: Prepares function-ID maps ===== #
map_extfun = {
              "tosthread_sleep":0, "tosthread_create":1,

              "led0On":2, "led1On":3, "led2On":4, 
              "led0Off":5, "led1Off":6, "led2Off":7, 
              "led0Toggle":8, "led1Toggle":9, "led2Toggle":10,
              "getLeds":11, "setLeds":12,
              
              "reboot":13,

              "get_nodeid":14, "get_nexthop":15,
              "get_globaltime":16, "get_localtime":17,
              "get_rfpower":18, "get_istimesync":19,
              "get_globaltimems":20, "get_localtimems":21,
              "get_clockfreq":22, "get_platform":23,
              "get_hopcount":24, "get_rfchannel":25,

              "tenet_get_tid":26, "tenet_get_src":27, "tenet_get_numtasks":28,

              "read_voltage":29, "read_internal_temperature":30,

              "tenet_send":31, "tenet_sendto":32,

              "read_tsr_sensor":33, "read_par_sensor":34,
              "read_temperature":35, "read_humidity":36,

              "__divmodhi4":36
              }

