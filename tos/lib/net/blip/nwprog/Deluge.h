/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
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
  NWPROG_CMD_READ  = 3,
  NWPROG_CMD_LIST  = 4,
  NWPROG_CMD_BOOT  = 5,
  NWPROG_CMD_REBOOT= 6,
  NWPROG_CMD_READDONE = 7,
  NWPROG_CMD_IMAGEIFO = 8,
};

enum {
  NWPROG_ERROR_OK = 0,
};

enum{
  PATCH_CMD_UPLOAD = 16,
  PATCH_CMD_COPY   = 17,
};

nx_struct ShortDelugeIdent {
  nx_uint8_t   appname[16];
  nx_uint8_t   username[16];
  nx_uint8_t   hostname[16];
  nx_uint32_t  timestamp;
};

typedef nx_struct prog_req {
  nx_uint8_t cmd;
  nx_uint8_t imgno;
  nx_union {
    nx_uint32_t offset;
    nx_uint32_t when;
    nx_uint32_t nimages;
  } cmd_data;
  nx_uint8_t data[0];
} prog_req_t;

typedef nx_struct prog_reply {
  nx_uint8_t error;
  nx_uint8_t pad;
  nx_struct prog_req req;
} prog_reply_t;

#endif
