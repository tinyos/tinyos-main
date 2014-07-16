1. PREFACE:

  This is a re-implementation of the C serial forwarder, covering the
  same functionality with some improvements. 

  It maintains the features of the C version (low CPU usage, small
  memory footprint), but with increased reliability: it does not loose
  packets while it waits for an ACK from the mote. In addition it has
  a control interface listening on a port, so if you run it as a
  daemon you can still ask it for various statistics, start and stop
  additional SFs for individual motes...

  C++ makes this implementation a bit more readable. 

2. INSTALLATION:

  Make sure that your environment has a C++ compiler, supports POSIX
  threads and can make a select on files and on sockets.

  cd to src

  Open the Makefile and adjust the CC variable and the CFLAGS to match
  your environment. Please pay attention to the -c (compile only) flag
  in the stem rule. If you use a Linux and g++ you should be fine out
  of the box.

  run make and wait

  Your compiler might issue a warning: 

    "sfpacket.cpp: warning: comparison is always true due to limited range
       of data type"

  you can safely ignore it.

  You should end up with an exectuable called sf in this directory, copy
  it whereever you need it.

  TODO: some of the things can be caught if we use a automake/autoconf
  environment. This is an overkill until we iron out the different
  platforms.

3. USAGE
  Start it with: sf 
  or           : sf control-port PORT_NUMBER daemon

  Arguments:
        control-port PORT_NUMBER : TCP port on which commands are
        accepted, to play with it: use telnet. Commands are executed
        once a new line '\n' is entered. If you write your own client,
        make sure that it sends a terminating '\n' after the command. 
	
        daemon : this switch (if present) makes sf aware that it may
        be running as a daemon. Currently this only means that it will
        not read from stdin.

  No arguments:
        If sf is started without arguments it listen on
        standard input for commands (for a list type "help" when sf is running).
        If it is started with a given control-port (e.g.: sf control-port 9009)
        sf listen on the given TCP control port _and_ the standard
        input.

  Once you have it running and accepting commands either via the TCP
  port or via stdin, you can issue several commands (executed once a
  new line '\n' is entered):

  start - starts a sf-server on a given port and device
  stop  - stops a running sf-server
  list  - lists all running sf-servers
  info  - prints out some information about a given sf-server
  close - closes the TCP connection to the control-client
  exit  - immediatly exits and kills all running sf-servers

  By typing "help" followd by a command (e.g.: "help start" detailed
  information about that command is printed.

  The parameters of start are modelled after the command line of the C
  serial forwarder.

  The info command prints out some stats:

    The TCP SIDE (this is where your PC side application hooks up to the
    SF) prints:

    clients: the number of clients (or PC side apps/MoteIFs) connected to
      this port. 

    packets read: correct packets received via TCP

    packets written: packets send vi TCP to your application

    The SERIAL LINE interface prints:
      packets read: the number of packets read from the mote.

      dropped: the number of packets that could not be send via TCP
       (usually because no client was connected)

      bad: number of packets with CRC or length errors, often 1: it
       needs a packet to synchronize to the stream.

      packets written: packets written to the mote

	      dropped: number of packets where no ACK was received
	      from the mote after 25 retries (with linear increasing
	      backoff). Go check your mote application ;-)

  	      total retries: total number of packets where ACKs from
	      the motes where not received in time. These packets are
	      usually ACKed on a retry, these are not in failures in
	      general.

4. AUTHOR

  Philipp Huppertz <huppertz@tkn.tu-berlin.de>

5. MAINTAINERS

  Andreas Koepke <koepke@tkn.tu-berlin.de>
  Jan Hauer      <hauer@tkn.tu-berlin.de>

6. KNOWN BUGS

   - Only one control client is allowed at one point in time.
   - The daemon switch is less powerful than it promises.
   - serialprotocol.h should be generated, as is done for the C
     version.

7. LICENSE

  Copyright (c) 2007, Technische Universitaet Berlin
  All rights reserved.
 
  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions 
  are met:
  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  - Redistributions in binary form must reproduce the above copyright 
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  - Neither the name of the Technische Universitaet Berlin nor the names 
    of its contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.
 
  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
