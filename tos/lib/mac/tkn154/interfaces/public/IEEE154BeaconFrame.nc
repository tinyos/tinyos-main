/* 
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:00:34 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include <TKN154.h>

interface IEEE154BeaconFrame 
{
 
 /**
   * Reads the Pending Address Specification of a beacon frame.
   *
   * @param frame         the beacon frame
   * @param pendAddrSpec  a pointer to where the Pending Address 
   *                      Specification should be written
   * @return              FAIL if the frame is not a beacon frame,
   *                      SUCCESS otherwise
   */
  command error_t getPendAddrSpec(message_t* frame, uint8_t* pendAddrSpec);

 /**
   * Reads the Pending Addresses of a given type (short or extended) from a 
   * beacon frame.
   *
   * @param frame         the beacon frame
   * @param addrMode      the address mode of the sought addresses, either 
   *                      ADDR_MODE_SHORT_ADDRESS or ADDR_MODE_EXTENDED_ADDRESS
   * @param buffer        a pointer to an array of "bufferSize" addresses
   * @param bufferSize    number of address entries in the buffer
   *
   * @return              FAIL if the frame is not a beacon frame,
   *                      SUCCESS otherwise
   */
  command error_t getPendAddr(message_t* frame, uint8_t addrMode, 
      ieee154_address_t buffer[], uint8_t bufferSize);

 /**
   * Determines whether the local macShortAddress or aExtendedAddress
   * (as currently registered in the PIB) is part of the pending 
   * address list of a beacon.
   *
   * @param frame the beacon frame
   * 
   * @return      ADDR_MODE_NOT_PRESENT if the frame is not a beacon
   *              beacon frame, or the local address is not part of
   *              the pending address list,
   *              ADDR_MODE_SHORT_ADDRESS if the local macShortAddress 
   *              is part of the pending address list,
   *              ADDR_MODE_EXTENDED_ADDRESS if the local aExtendedAddress
   *              is part of the pending address list
   */
  command uint8_t isLocalAddrPending(message_t* frame);

 /**
   * Parses the PAN Descriptor of a beacon frame. Since a frame
   * does not include information about the channel that it was 
   * received on this information must be provided by the caller. 
   *
   * @param frame          the beacon frame
   * @param LogicalChannel will be written to PANDescriptor->LogicalChannel
   * @param ChannelPage    will be written to PANDescriptor->ChannelPage
   * @param PANDescriptor  a pointer to a PAN Descriptor, that will hold 
   *                       the PAN Descriptor as parsed of the beacon frame 
   * @param bufferSize     number of address entries in the buffer
   *
   * @return               SUCCESS if the frame is a valid beacon frame and the 
   *                       PANDescriptor was successfully parsed, FAIL
   *                       otherwise
   */
  command error_t parsePANDescriptor(message_t *frame, uint8_t LogicalChannel,
      uint8_t ChannelPage, ieee154_PANDescriptor_t *PANDescriptor);  

 /**
   * Returns a pointer to the beacon payload.
   *
   * @param frame         the beacon frame
   * @return              a pointer to the beacon payload, or, if the
   *                      frame is not a beacon frame, a pointer to
   *                      the MAC payload. If the frame was received
   *                      while in promiscuous mode, then this command
   *                      returns a pointer to the first byte of the MHR.
   */
  command void* getBeaconPayload(message_t* frame);

  /**
    * Returns the length of the beacon payload portion of the frame
    * (in byte).
    *
    * @param  frame   the frame 
    * @return         the length (in byte) of the frame's beacon payload
    *                 portion, or, if the frame is not a beacon frame 
    *                 the length of the MAC payload. If the frame 
    *                 was received while in promiscuous mode, then 
    *                 this command returns the length of MHR + MAC Payload.
    */
  command uint8_t getBeaconPayloadLength(message_t* frame);

 /**
   * Returns the (beacon) sequence number of the frame.
   *
   * @param frame     the frame
   * @return          sequence number of the frame
   */
  command uint8_t getBSN(message_t* frame);  
}
