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

enum {
  DELUGE_INVALID_UID = 0xffffffff,
  DELUGE_NUM_VOLUMES = 4, 
  DELUGE_KEY = 0xDE00,
  DELUGE_AM_FLASH_VOL_MANAGER = 0x53,
  DELUGE_AM_DELUGE_MANAGER = 0x54,
};

enum {
  DELUGE_CMD_STOP = 1,
  DELUGE_CMD_LOCAL_STOP = 2,
  DELUGE_CMD_ONLY_DISSEMINATE = 3,
  DELUGE_CMD_DISSEMINATE_AND_REPROGRAM = 4,
  DELUGE_CMD_REPROGRAM = 5, // Reprogram the local mote
  DELUGE_CMD_REBOOT = 6,    // Reboot the local mode
};

#define UQ_DELUGE_METADATA "DelugeMetadata.client"
#define UQ_DELUGE_VOLUME_MANAGER "DelugeVolumeManager.client"

typedef nx_struct DelugeCmd {
  nx_uint8_t type;
  nx_uint32_t uidhash;  // unique id of image
  nx_uint8_t  imgNum;   // image number
  nx_uint32_t size;     // size of the image
} DelugeCmd;

typedef struct BootArgs {
  uint16_t  address;
  uint32_t imageAddr;
  uint8_t  gestureCount;
  bool     noReprogram;
} BootArgs;

#endif
