/* 
 * Copyright (c) 2008, Technische Universitaet Berlin All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.  - Redistributions in
 * binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other
 * materials provided with the distribution.  - Neither the name of the
 * Technische Universitaet Berlin nor the names of its contributors may be used
 * to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $ $Date: 2008-06-16 18:00:33 $ 
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154.h" 
interface FrameUtility
{
  /* Writes the addressing fields in the MAC header of a frame
   * and returns number of bytes in the MAC header.*/
  async command uint8_t writeHeader(
      uint8_t* mhr,
      uint8_t DstAddrMode,
      uint16_t DstPANId,
      ieee154_address_t* DstAddr,
      uint8_t SrcAddrMode,
      uint16_t SrcPANId,
      const ieee154_address_t* SrcAddr,
      bool PANIDCompression);

  /* Determines the lenght of the MAC header depending on the frame control field*/ 
  async command error_t getMHRLength(uint8_t fcf1, uint8_t fcf2, uint8_t *len);

  /* Returns TRUE if source address is the current coordinator and
   * src PAN is current PAN */
  command bool isBeaconFromCoord(message_t *frame);

  /* writes the local extended address in little endian format */
  async command void copyLocalExtendedAddressLE(uint8_t *destLE);

  /* writes the coordinator's extended address in little endian format */
  command void copyCoordExtendedAddressLE(uint8_t *destLE);

  /* converts a uint64_t to little endian */
  async command void convertToLE(uint8_t *destLE, const uint64_t *srcNative);

  /* converts little endian to a uint64_t */
  async command void convertToNative(uint64_t *destNative, const uint8_t *srcLE);
}
