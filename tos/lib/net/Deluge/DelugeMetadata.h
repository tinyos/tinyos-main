/*
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __DELUGE_METADATA_H__
#define __DELUGE_METADATA_H__

#define DELUGE_METADATA_SIZE 16

typedef int16_t imgvnum_t;
typedef uint8_t  imgnum_t;
typedef uint8_t   pgnum_t;

typedef struct DelugeImgDesc {
  uint32_t  uid;            // unique id of image
  imgvnum_t vNum;           // version num of image
  imgnum_t  imgNum;         // image number
  pgnum_t   numPgs;         // num pages of complete image
  uint16_t  crc;            // crc for vNum and numPgs
  uint8_t   numPgsComplete; // numPgsComplete in image
  uint8_t   reserved;
  uint16_t  size;           // size of the whole image (metadata + CRCs + ident + binary)
} DelugeImgDesc;

#endif
