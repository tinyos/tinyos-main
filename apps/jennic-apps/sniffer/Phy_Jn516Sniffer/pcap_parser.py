#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2014, Technische Universitaet Berlin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions 
# are met:
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright 
#   notice, this list of conditions and the following disclaimer in the 
#   documentation and/or other materials provided with the distribution.
# - Neither the name of the Technische Universitaet Berlin nor the names 
#   of its contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Tool that takes the output of Phy_Jn516Sniffer and converts it into 
pcap file format. This can be loaded into Wireshark to visualize the 
traffic on 802.15.4.
You can either define an input file using -f or let this script
read from stdin (pipe).
There is some buffering involved in the pipe approach.
This can be prevented by using python option '-u' and linux tool 'stdbuf -oL'
If you don't specifiy an output file it will output to stdout.
 
Usage:
    pcap_file_writer.py [options] [-q | -v]


Options:
    -o OUTPUT_FILE            output file to write the pcap file
    -i INPUT_FILE             file to load the sniffer output from
 
Other options:
    -h, --help                show this help message and exit
    -q, --quiet               print less text
    -v, --verbose             print more text
    --version                 show version and exit
"""
 
__author__ = "Jasper Buesch"
__copyright__ = "Copyright (c) 2014, Technische Universität Berlin"
__version__ = "0.1.0"
__email__ = "buesch@tkn.tu-berlin.de"
 

# Props go to the author of (http://www.kroosec.com/2012/10/a-look-at-pcap-file-format.html) 
# where I derived the parsing of pcap files from

import struct
import datetime
import time
import logging
import sys

MAGIC_NUMBER = 0xa1b2c3d4
VERSION_MAJOR = 02
VERSION_MINOR = 04
TIMEZONE = 0
ACCURACY = 0
MAX_PACKET_SIZE = 127
LINK_LAYER_PROTOCOL = 195


class PcapFileWriter(object):
    def __init__(self, filename=None):
        self.filename = filename
        self.file_header_written = False

    def create_pcap_header(self):
        self.file_header_written = True
        f = ""
        # gloabal header
        # < means little endian, I is uint32, H is uint16
        f += struct.pack("<I", MAGIC_NUMBER)
        f += struct.pack("<H", VERSION_MAJOR)
        f += struct.pack("<H", VERSION_MINOR)
        f += struct.pack("<I", TIMEZONE)
        f += struct.pack("<I", ACCURACY)
        f += struct.pack("<I", MAX_PACKET_SIZE)
        f += struct.pack("<I", LINK_LAYER_PROTOCOL)
        return f

    def create_pcap_frame(self, frame, timestamp=None):
        # make sure to write the file header first to the pcap file!
        if timestamp is None:
            timestamp = datetime.datetime.now()
        f = ""
        # frame header
        #4 byte timestamp seconds, 4 byte timestamp us, 4 byte recvd recorded length, 4 byte file packet length
        f += struct.pack("<I", int(time.mktime(timestamp.timetuple())))
        f += struct.pack("<I", int(timestamp.microsecond))
        length = len(frame)
        f += struct.pack("<I", length)
        f += struct.pack("<I", length)

        f += frame
        return f

    def write_to_pcap_file(self, frame, file_attr="a"):
        if self.filename:
            with open(self.filename, file_attr) as fily:
                fily.write(frame)
        else:
            print "write_pcap_file: No filename defined!: ", f



def main(args):
    output_file = args["-o"]
    input_filename = args["-i"]

    dumper = PcapFileWriter(output_file)
    header = dumper.create_pcap_header()
    if output_file:
        dumper.write_to_pcap_file(header, file_attr="w")
    else:
        sys.stdout.write(header)

    if not input_filename:
        line = sys.stdin.readline()
        while line:
            line = sys.stdin.readline()
            if line.startswith("listen"):
                continue
            try:
                ts = datetime.datetime.fromtimestamp(float(line.split()[0]))
                data = line.split()[-1]
                frame = dumper.create_pcap_frame(data.decode("HEX"), timestamp=ts)
                if output_file:
                    dumper.write_to_pcap_file(frame)
                else:
                    sys.stdout.write(frame)
            except TypeError:
                continue
    else:
        with open(input_filename, "r") as f:
            line = f.readline()
            while line:
                if line.startswith("listen"):
                    continue
                ts = datetime.datetime.fromtimestamp(float(line.split()[0]))
                data = line.split()[-1]
                frame = dumper.create_pcap_frame(data.decode("HEX"), timestamp=ts)
                if output_file:
                    dumper.write_to_pcap_file(frame)
                else:
                    sys.stdout.write(frame)
                    sys.stdout.flush()
                line = f.readline()

##############################################################

if __name__ == "__main__":
    try:
        from docopt import docopt
    except:
        print("""
        Please install docopt using:
            pip install docopt==0.6.1
        For more refer to:
        https://github.com/docopt/docopt
        """)
        raise
 
    args = docopt(__doc__, version=__version__)
 
    log_level = logging.INFO  # default
    if args['--verbose']:
        log_level = logging.DEBUG
    elif args['--quiet']:
        log_level = logging.ERROR
    logging.basicConfig(level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    main(args)
