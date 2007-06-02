/*
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
 * Copyright (c) 2007 Johns Hopkins University.
 * All rights reserved.
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

#include "AM.h"

module NetProgM {
  provides {
    interface NetProg;
    interface Init;
  }
  uses {
    interface DelugeStorage[uint8_t img_num];
    interface InternalFlash as IFlash;
    interface Crc;
    interface DelugeMetadata;
    interface Leds;
  }
}

implementation {

  uint16_t computeTosInfoCrc(NetProg_TOSInfo* tosInfo)
  {
    return call Crc.crc16(tosInfo, sizeof(NetProg_TOSInfo)-2);
  }

  void writeTOSinfo()
  {
    NetProg_TOSInfo tosInfo;
    uint16_t crc;
    call IFlash.read((uint8_t*)IFLASH_TOS_INFO_ADDR, &tosInfo, sizeof(tosInfo));
    tosInfo.addr = TOS_NODE_ID;
    tosInfo.groupId = TOS_AM_GROUP;
    crc = computeTosInfoCrc(&tosInfo);
    // don't write if data is already correct
    if (tosInfo.crc == crc)
      return;
    tosInfo.crc = crc;
    call IFlash.write((uint8_t*)IFLASH_TOS_INFO_ADDR, &tosInfo, sizeof(tosInfo));
  }

  command error_t Init.init()
  {

    NetProg_TOSInfo tosInfo;

    call IFlash.read((uint8_t*)IFLASH_TOS_INFO_ADDR, &tosInfo, sizeof(tosInfo));

    if (tosInfo.crc == computeTosInfoCrc(&tosInfo)) {
      // TOS_AM_GROUP is not a variable in T2
      //      TOS_AM_GROUP = tosInfo.groupId;
      atomic TOS_NODE_ID = tosInfo.addr;
    }
    else {
      writeTOSinfo();
    }
 
    return SUCCESS;
  }
  
  command error_t NetProg.reboot()
  {
    atomic {
      writeTOSinfo();
      netprog_reboot();
    }
    return FAIL;
  }
  
  command error_t NetProg.programImgAndReboot(uint8_t img_num)
  {
    tosboot_args_t args;
    DelugeNodeDesc nodeDesc;
    DelugeImgDesc *imgDesc;
    
    atomic {
      writeTOSinfo();
      
      args.imageAddr = call DelugeStorage.getPhysicalAddress[img_num](0);
      args.gestureCount = 0xff;
      args.noReprogram = FALSE;
      call IFlash.write((uint8_t*)TOSBOOT_ARGS_ADDR, &args, sizeof(args));
      
      // Write info about what img to disseminate after reboot
      imgDesc = call DelugeMetadata.getImgDesc(img_num);
      nodeDesc.uid = imgDesc->uid;
      nodeDesc.imgNum = img_num;
      call IFlash.write((uint8_t*)IFLASH_NODE_DESC_ADDR, &nodeDesc, sizeof(nodeDesc));
      
      // reboot
      netprog_reboot();
    }

    // couldn't reboot
    return FAIL;
  }

  default command storage_addr_t DelugeStorage.getPhysicalAddress[uint8_t img_num](storage_addr_t addr) { return 0xFFFFFFFF; }

}
