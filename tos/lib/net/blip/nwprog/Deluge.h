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

#ifndef __DELUGE_H__
#define __DELUGE_H__

typedef nx_struct DelugeIdent {
  nx_uint32_t  uidhash;        // unique id of the image
  nx_uint32_t  size;           // size of the whole image (ident + CRCs + binary)
  nx_uint8_t   numPgs;         // number of pages of complete image
  nx_uint8_t   reserved;
  nx_uint16_t  crc;            // crc over the above 4 fields
  nx_uint8_t   appname[16];
  nx_uint8_t   username[16];
  nx_uint8_t   hostname[16];
  nx_uint8_t   platform[16];
  nx_uint32_t  timestamp;
  nx_uint32_t  userhash;
} DelugeIdent;

typedef nx_struct DelugePatchCmd {
  nx_uint16_t linenum;      // sequence number of patches, starting from 0
  nx_uint8_t  cmd;          // patch cmd: 16 for upload, 17 for copy
  nx_uint16_t dst_offset;
  nx_uint16_t data_length;  // byte length of the data
  nx_uint16_t src_offset;
  nx_uint8_t  reserved[7];
  nx_uint8_t  data[0];      // data for the upload command
} DelugePatchCmd;

enum {
  DELUGE_INVALID_UID = 0xffffffff,
  DELUGE_NUM_VOLUMES = 4, 
  DELUGE_IDENT_SIZE                 = 128,
  DELUGE_MAX_PAGES                  = 128,
  DELUGE_CRC_SIZE                   = sizeof(uint16_t),
  DELUGE_CRC_BLOCK_SIZE             = DELUGE_MAX_PAGES * DELUGE_CRC_SIZE,
  DELUGE_BYTES_PER_PAGE             = 23 * 48,
};

enum {
  MAX_PATCH_DATA_SIZE = 512,
  PATCH_LINE_SIZE = 16,
};

#define UQ_DELUGE_METADATA "DelugeMetadata.client"
#define UQ_DELUGE_VOLUME_MANAGER "DelugeVolumeManager.client"
#define UQ_DELUGE_VERIFY "DelugeVerify.client"
#define UQ_DELUGE_PATCH "DelugePatch.client"
#define UQ_DELUGE_READ_IDENT "DelugeReadIdent.client"

typedef struct BootArgs {
  uint16_t  address;
  uint32_t imageAddr;
  uint8_t  gestureCount;
  bool     noReprogram;
} BootArgs;

enum {
  NWPROG_CMD_ERASE = 1,
  NWPROG_CMD_WRITE = 2,
};

enum{
  PATCH_CMD_UPLOAD = 16,
  PATCH_CMD_COPY   = 17,
};

typedef nx_struct prog_req {
  nx_uint8_t cmd;
  nx_uint8_t imgno;
  nx_uint16_t offset;
  nx_uint8_t data[0];
} prog_req_t;

typedef nx_struct prog_reply {
  nx_uint8_t error;
  nx_struct prog_req req;
} prog_reply_t;

#endif
