/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#ifndef FLASHVOLUMEMANAGER_H
#define FLASHVOLUMEMANAGER_H

#define SERIALMSG_ERASE     0
#define SERIALMSG_WRITE     1
#define SERIALMSG_READ      2
#define SERIALMSG_CRC       3
#define SERIALMSG_ADDR      4
#define SERIALMSG_REPROG    5
#define SERIALMSG_DISS      6
#define SERIALMSG_REPROG_BS 7
#define SERIALMSG_SYNC      8

typedef nx_struct SerialReqPacket {
  nx_uint8_t msg_type;
  nx_uint8_t img_num;
  nx_uint16_t offset;
  nx_uint16_t len;
  nx_uint8_t data[0];
} SerialReqPacket;

#define SERIALMSG_SUCCESS 0
#define SERIALMSG_FAIL    1

typedef nx_struct SerialReplyPacket {
  nx_uint8_t error;
  nx_uint8_t data[0];
} SerialReplyPacket;

#endif
