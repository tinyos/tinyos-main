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

module DelugeP
{
  uses {
    interface Leds;
    interface Notify<uint8_t> as StorageReadyNotify;
    interface DisseminationUpdate<DelugeDissemination>;
    interface DisseminationValue<DelugeDissemination>;
    interface StdControl as StdControlDissemination;
    interface DelugeMetadata;
    interface ObjectTransfer;
    interface NetProg;
    interface InternalFlash as IFlash;
    interface SplitControl as RadioSplitControl;
    
#ifdef DELUGE_BASESTATION
    interface Notify<uint8_t> as DissNotify;
    interface Notify<uint8_t> as ReprogNotify;
#endif
  }
}

implementation
{
  uint32_t recv_uid = 0xffffffff;
  uint16_t recv_size = 0xffff;
  uint8_t recv_imgNum = 0xff;
  
  /**
   * Starts the radio
   */
  event void StorageReadyNotify.notify(uint8_t val)
  {
    call RadioSplitControl.start();
  }
  
#ifdef DELUGE_BASESTATION
  /**
   * Starts disseminating image information
   */
  event void DissNotify.notify(uint8_t new_img_num)
  {
    DelugeImgDesc* imgDesc = call DelugeMetadata.getImgDesc(new_img_num);
    if (imgDesc->uid != DELUGE_INVALID_UID) {
      DelugeDissemination delugeDis;
      
      call ObjectTransfer.stop();
      
      delugeDis.uid = imgDesc->uid;
      delugeDis.vNum = imgDesc->vNum;
      delugeDis.imgNum = new_img_num;
      delugeDis.size = imgDesc->size;
      delugeDis.msg_type = DISSMSG_DISS;
      
      call DisseminationUpdate.change(&delugeDis);   // Disseminates command
      call ObjectTransfer.publish(delugeDis.uid,
                                  delugeDis.size,
                                  delugeDis.imgNum);   // Prepares to publish image data
    }
  }
  
  event void ReprogNotify.notify(uint8_t new_img_num)
  {
    DelugeDissemination delugeDis;
    
    delugeDis.uid = 0;
    delugeDis.vNum = 0;
    delugeDis.imgNum = new_img_num;
    delugeDis.size = 0;
    delugeDis.msg_type = DISSMSG_REPROG;
    
    call DisseminationUpdate.change(&delugeDis);   // Disseminates command
  }
#endif

  /**
   * Receives a disseminated message. If the message contains information about a
   * newer image, then we should grab this image from the network
   */
  event void DisseminationValue.changed()
  {
    const DelugeDissemination *delugeDis = call DisseminationValue.get();
    DelugeImgDesc *imgDesc = call DelugeMetadata.getImgDesc(delugeDis->imgNum);
        
    switch (delugeDis->msg_type) {
      case DISSMSG_DISS:
        if (imgDesc->uid == delugeDis->uid && imgDesc->uid != DELUGE_INVALID_UID) {
          if (imgDesc->vNum < delugeDis->vNum) {
            recv_uid = delugeDis->uid;
            recv_size = delugeDis->size;
            recv_imgNum = delugeDis->imgNum;
            call ObjectTransfer.receive(delugeDis->uid, delugeDis->size, delugeDis->imgNum);
          }
        } else {
          recv_uid = delugeDis->uid;
          recv_size = delugeDis->size;
          recv_imgNum = delugeDis->imgNum;
          call ObjectTransfer.receive(delugeDis->uid, delugeDis->size, delugeDis->imgNum);
        }
        
        break;
      case DISSMSG_REPROG:
        if (imgDesc->uid != DELUGE_INVALID_UID) {
          DelugeNodeDesc nodeDesc;
          call IFlash.read((uint8_t*)IFLASH_NODE_DESC_ADDR,
                           &nodeDesc,
                           sizeof(DelugeNodeDesc));   // Reads which image was just reprogrammed
          if (nodeDesc.uid != imgDesc->uid || nodeDesc.vNum != imgDesc->vNum) {
            call NetProg.programImgAndReboot(delugeDis->imgNum);
          }
        }
        
        break;
    }
  }
  
  event void ObjectTransfer.receiveDone(error_t error)
  {
    call Leds.set(LEDS_LED1 | LEDS_LED2);
    call ObjectTransfer.publish(recv_uid, recv_size, recv_imgNum);
  }

  /**
   * Prepares to publish the image that was just reprogrammed
   */
  event void RadioSplitControl.startDone(error_t error)
  {
    if (error == SUCCESS) {
      call StdControlDissemination.start();
    }
  }
  
  event void RadioSplitControl.stopDone(error_t error) {}
  
  default async void command Leds.set(uint8_t val) {}
}
