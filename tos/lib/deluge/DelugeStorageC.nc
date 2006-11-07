// $Id: DelugeStorageC.nc,v 1.3 2006-11-07 19:31:18 scipio Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

configuration DelugeStorageC {
  provides {
    interface DelugeDataRead as DataRead;
    interface DelugeDataWrite as DataWrite;
    interface DelugeMetadataStore as MetadataStore;
    interface DelugeStorage;
  }
}
implementation {

  components Main, DelugeStorageM as Storage, LedsC as Leds;

  DataRead = Storage;
  DataWrite = Storage;
  DelugeStorage = Storage;
  MetadataStore = Storage;

  Storage.Leds -> Leds;

  components new BlockStorageC() as BlockStorage0;
  Storage.BlockRead[DELUGE_VOLUME_ID_0] -> BlockStorage0;
  Storage.BlockWrite[DELUGE_VOLUME_ID_0] -> BlockStorage0;
  Storage.Mount[DELUGE_VOLUME_ID_0] -> BlockStorage0;
  Storage.StorageRemap[DELUGE_VOLUME_ID_0] -> BlockStorage0;
#if DELUGE_NUM_IMAGES >= 2
  components new BlockStorageC() as BlockStorage1;
  Storage.BlockRead[DELUGE_VOLUME_ID_1] -> BlockStorage1;
  Storage.BlockWrite[DELUGE_VOLUME_ID_1] -> BlockStorage1;
  Storage.Mount[DELUGE_VOLUME_ID_1] -> BlockStorage1;
  Storage.StorageRemap[DELUGE_VOLUME_ID_1] -> BlockStorage1;
#if DELUGE_NUM_IMAGES >= 3
  components new BlockStorageC() as BlockStorage2;
  Storage.BlockRead[DELUGE_VOLUME_ID_2] -> BlockStorage2;
  Storage.BlockWrite[DELUGE_VOLUME_ID_2] -> BlockStorage2;
  Storage.Mount[DELUGE_VOLUME_ID_2] -> BlockStorage2;
  Storage.StorageRemap[DELUGE_VOLUME_ID_2] -> BlockStorage2;
#if DELUGE_NUM_IMAGES >= 4
  components new BlockStorageC() as BlockStorage3;
  Storage.BlockRead[DELUGE_VOLUME_ID_3] -> BlockStorage3;
  Storage.BlockWrite[DELUGE_VOLUME_ID_3] -> BlockStorage3;
  Storage.Mount[DELUGE_VOLUME_ID_3] -> BlockStorage3;
  Storage.StorageRemap[DELUGE_VOLUME_ID_3] -> BlockStorage3;
#if DELUGE_NUM_IMAGES >= 5
  components new BlockStorageC() as BlockStorage4;
  Storage.BlockRead[DELUGE_VOLUME_ID_4] -> BlockStorage4;
  Storage.BlockWrite[DELUGE_VOLUME_ID_4] -> BlockStorage4;
  Storage.Mount[DELUGE_VOLUME_ID_4] -> BlockStorage4;
  Storage.StorageRemap[DELUGE_VOLUME_ID_4] -> BlockStorage4;
#if DELUGE_NUM_IMAGES >= 6
  components new BlockStorageC() as BlockStorage5;
  Storage.BlockRead[DELUGE_VOLUME_ID_5] -> BlockStorage5;
  Storage.BlockWrite[DELUGE_VOLUME_ID_5] -> BlockStorage5;
  Storage.Mount[DELUGE_VOLUME_ID_5] -> BlockStorage5;
  Storage.StorageRemap[DELUGE_VOLUME_ID_5] -> BlockStorage5;
#if DELUGE_NUM_IMAGES >= 7
  components new BlockStorageC() as BlockStorage6;
  Storage.BlockRead[DELUGE_VOLUME_ID_6] -> BlockStorage6;
  Storage.BlockWrite[DELUGE_VOLUME_ID_6] -> BlockStorage6;
  Storage.Mount[DELUGE_VOLUME_ID_6] -> BlockStorage6;
  Storage.StorageRemap[DELUGE_VOLUME_ID_6] -> BlockStorage6;
#if DELUGE_NUM_IMAGES >= 8
  components new BlockStorageC() as BlockStorage7;
  Storage.BlockRead[DELUGE_VOLUME_ID_7] -> BlockStorage7;
  Storage.BlockWrite[DELUGE_VOLUME_ID_7] -> BlockStorage7;
  Storage.Mount[DELUGE_VOLUME_ID_7] -> BlockStorage7;
  Storage.StorageRemap[DELUGE_VOLUME_ID_7] -> BlockStorage7;
#endif
#endif
#endif
#endif
#endif
#endif
#endif

}
