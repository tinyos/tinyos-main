/*
 * Copyright (c) 2008 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#ifndef SERIALLOADER_H
#define SERIALLOADER_H

#define MAX_BIN_SIZE 2000

#define SERIALMSG_ERASE 0
#define SERIALMSG_WRITE 1
#define SERIALMSG_READ  2
#define SERIALMSG_CRC   3
#define SERIALMSG_LEDS  5
#define SERIALMSG_RUN   7

typedef nx_struct SerialReqPacket {
  nx_uint8_t msg_type;
  nx_uint8_t pad;
  nx_uint16_t offset;
  nx_uint16_t len;
  nx_uint8_t data[0];
} SerialReqPacket;

#define SERIALMSG_SUCCESS 0
#define SERIALMSG_FAIL    1

typedef nx_struct SerialReplyPacket {
  nx_uint8_t error;
  nx_uint8_t pad;
  nx_uint8_t data[0];
} SerialReplyPacket;

#endif
