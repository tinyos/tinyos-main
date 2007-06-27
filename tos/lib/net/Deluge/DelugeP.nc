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
    interface Notify<uint8_t> as ReprogNotify;
#endif
  }
}

implementation
{
  uint8_t img_num;
  
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
  event void ReprogNotify.notify(uint8_t new_img_num)
  {
    DelugeDissemination delugeDis;
    DelugeImgDesc *imgDesc;
    
    imgDesc = call DelugeMetadata.getImgDesc(new_img_num);
    if (imgDesc->uid != DELUGE_INVALID_UID) {
      call ObjectTransfer.stop();
      call Leds.led0Toggle();
      img_num = new_img_num;
      
      delugeDis.uid = imgDesc->uid;
      delugeDis.vNum = imgDesc->vNum;
      delugeDis.imgNum = img_num;
      delugeDis.size = imgDesc->size;
      
      call DisseminationUpdate.change(&delugeDis);   // Disseminates image information
      call ObjectTransfer.publish(delugeDis.uid,
                                  delugeDis.size,
                                  delugeDis.imgNum);   // Prepares to publish image data
    }
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
    
    if (imgDesc->uid == delugeDis->uid) {
      if (imgDesc->vNum < delugeDis->vNum) {
        img_num = delugeDis->imgNum;   // Note which image number to boot
        call ObjectTransfer.receive(delugeDis->uid, delugeDis->size, delugeDis->imgNum);
      }
    } else {
      img_num = delugeDis->imgNum;   // Note which image number to boot
      call ObjectTransfer.receive(delugeDis->uid, delugeDis->size, delugeDis->imgNum);
    }
  }

  /**
   * Reboots and reprograms with the newly received image
   */
  event void ObjectTransfer.receiveDone(error_t error)
  {
    call ObjectTransfer.stop();
    if (error == SUCCESS) {
      call NetProg.programImgAndReboot(img_num);
    }
  }

  /**
   * Prepares to publish the image that was just reprogrammed
   */
  event void RadioSplitControl.startDone(error_t error)
  {
    if (error == SUCCESS) {
      // Start publishing the current image
      DelugeImgDesc *imgDesc;
      DelugeNodeDesc nodeDesc;
      call IFlash.read((uint8_t*)IFLASH_NODE_DESC_ADDR,
                       &nodeDesc,
                       sizeof(DelugeNodeDesc));   // Reads which image was just reprogrammed
      imgDesc = call DelugeMetadata.getImgDesc(nodeDesc.imgNum);
      if (nodeDesc.uid == imgDesc->uid && imgDesc->uid != DELUGE_INVALID_UID) {
        call ObjectTransfer.publish(imgDesc->uid, imgDesc->size, imgDesc->imgNum);
      }
            
      call StdControlDissemination.start();
    }
  }
  
  event void RadioSplitControl.stopDone(error_t error) {}
}
