/*
* Copyright (c) 2008 Johns Hopkins University.
* All rights reserved.
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
 * @author JeongGil Ko
 * @author Razvan Musaloiu-E.
 * @author Jong Hyun Lim
 */

generic module SecAMSenderP(am_id_t id)
{
  provides {
    interface AMSend;
    interface CC2420SecurityMode;
  }

  uses {
    interface AMSend as SubAMSend;
    interface Packet as SecurityPacket;
    interface AMPacket;
    interface Leds;
  }
}

implementation
{
  uint32_t nonceCounter = 0;
  uint8_t secLevel = NO_SEC;
  uint8_t keyIndex = 0;
  uint8_t reserved = 0; // skip in cc2420 implementations
  uint8_t micLength = 0;
  uint8_t length;

  command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len)
  {
    cc2420_header_t* hdr = (cc2420_header_t*)msg->header;
    security_header_t* secHdr = (security_header_t*)&hdr->secHdr;

#if ! defined(TFRAMES_ENABLED)
    (uint8_t*)secHdr += 1;
#endif

    if(secHdr->secLevel == CBC_MAC_4 || secHdr->secLevel == CCM_4){
      micLength = 4;
    }else if(secHdr->secLevel == CBC_MAC_8 || secHdr->secLevel == CCM_8){
      micLength = 8;
    }else if(secHdr->secLevel == CBC_MAC_16 || secHdr->secLevel == CCM_16){
      micLength = 16;
    }

    return call SubAMSend.send(addr, msg, len + (((secHdr->secLevel >= CBC_MAC_4 && secHdr->secLevel <= CBC_MAC_16) || (secHdr->secLevel >= CCM_4 && secHdr->secLevel <= CCM_16)) ? micLength : 0));
  }

  command uint8_t AMSend.maxPayloadLength()
  {
    return call SecurityPacket.maxPayloadLength();
  }

  command void* AMSend.getPayload(message_t* msg, uint8_t len)
  {
    return call SecurityPacket.getPayload(msg, len);
  }

  command error_t AMSend.cancel(message_t* msg) { return call SubAMSend.cancel(msg); }
  event void SubAMSend.sendDone(message_t *msg, error_t error) { signal AMSend.sendDone(msg, error); }




  command error_t CC2420SecurityMode.setCtr(message_t* msg, uint8_t setKey, uint8_t setSkip)
  {
    cc2420_header_t* hdr = (cc2420_header_t*)msg->header;
    security_header_t* secHdr = (security_header_t*)&hdr->secHdr;

#if ! defined(TFRAMES_ENABLED)
    (uint8_t*)secHdr += 1;
#endif

    if (setKey > 1 || setSkip > 7){
      return FAIL;
    }
    secLevel = CTR;
    keyIndex = setKey;
    reserved = setSkip;

    nonceCounter++;

    secHdr->secLevel = secLevel;
    secHdr->keyMode = 1; // Fixed to 1 for now
    secHdr->reserved = reserved; //skip in cc2420
    secHdr->frameCounter = nonceCounter;
    secHdr->keyID[0] = keyIndex; // Always first position for now due to fixed keyMode
    hdr->fcf |= 1 << IEEE154_FCF_SECURITY_ENABLED;
    return SUCCESS;
  }



  command error_t CC2420SecurityMode.setCbcMac(message_t* msg, uint8_t setKey, uint8_t setSkip, uint8_t size)
  {
    cc2420_header_t* hdr = (cc2420_header_t*)msg->header;
    security_header_t* secHdr = (security_header_t*)&hdr->secHdr;
#if ! defined(TFRAMES_ENABLED)
    (uint8_t*)secHdr += 1;
#endif

    if (setKey > 1 || (size != 4 && size != 8 && size != 16) || (setSkip > 7)){
      return FAIL;
    }

    if(size == 4)
      secLevel = CBC_MAC_4;
    else if (size == 8)
      secLevel = CBC_MAC_8;
    else if (size == 16)
      secLevel = CBC_MAC_16;
    else
      return FAIL;
    keyIndex = setKey;
    reserved = setSkip;

    nonceCounter++;

    secHdr->secLevel = secLevel;
    secHdr->keyMode = 1; // Fixed to 1 for now
    secHdr->reserved = reserved; //skip in cc2420
    secHdr->frameCounter = nonceCounter;
    secHdr->keyID[0] = keyIndex; // Always first position for now due to fixed keyMode
    hdr->fcf |= 1 << IEEE154_FCF_SECURITY_ENABLED;

    return SUCCESS;
  }


  command error_t CC2420SecurityMode.setCcm(message_t* msg, uint8_t setKey, uint8_t setSkip, uint8_t size)
  {
    cc2420_header_t* hdr = (cc2420_header_t*)msg->header;
    security_header_t* secHdr = (security_header_t*)&hdr->secHdr;

#if ! defined(TFRAMES_ENABLED)
    (uint8_t*)secHdr += 1;
#endif

    if (setKey > 1 || (size != 4 && size != 8 && size != 16) || (setSkip > 7)){
      return FAIL;
    }

    if(size == 4)
      secLevel = CCM_4;
    else if (size == 8)
      secLevel = CCM_8;
    else if (size == 16)
      secLevel = CCM_16;
    else
      return FAIL;
    keyIndex = setKey;
    reserved = setSkip;

    nonceCounter++;

    secHdr->secLevel = secLevel;
    secHdr->keyMode = 1; // Fixed to 1 for now
    secHdr->reserved = reserved; //skip in cc2420
    secHdr->frameCounter = nonceCounter;
    secHdr->keyID[0] = keyIndex; // Always first position for now due to fixed keyMode
    hdr->fcf |= 1 << IEEE154_FCF_SECURITY_ENABLED;

    return SUCCESS;
  }
}
