*** SHIMMER - TinyOS 2.x platform support ***
=============================================
Konrad Lorincz
May 6, 2008

This directory contains tinyos 2.x platform support for the Intel
SHIMMER mote.  Please use the mailing list given below to post
questions and comments.


Usage
-----
You can compile and install applications for the SHIMMER platform just
like with any standard platform, "make shimmer install ..." (Note:
you must have a shimmer programming board).

For example, to complie and install Blink, do the following:

  $ cd $TOSROOT/apps/Blink
  $ make shimmer install bsl,X

where X is your serial port.

You may also want to test the radio.  Do this by compiling and
installing "$TOSROOT/apps/RadioCountToLeds" on TWO shimmers (for
sending and receiving radio messages).


Support
-------
  - Official documentation
    http://docs.tinyos.net/index.php/SHIMMER
  - Mailing list (requires subscription to post)
    https://www.eecs.harvard.edu/mailman/listinfo/shimmer-users


Copyright
---------
/*
 * Copyright (c) 2008
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

