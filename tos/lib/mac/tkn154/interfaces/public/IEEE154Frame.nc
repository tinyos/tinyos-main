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
 * $Revision: 1.3 $
 * $Date: 2009-03-04 18:31:46 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * The IEEE154Frame interface allows to access the content of a IEEE 802.15.4
 * frame.
 */

#include <TKN154.h>
#include <message.h>

interface IEEE154Frame 
{

 /**
   * Returns the source addressing mode of the frame.
   *
   * @param frame     the frame
   * @return          source addressing mode of the frame; either
   *                  ADDR_MODE_NOT_PRESENT, ADDR_MODE_RESERVED,
   *                  ADDR_MODE_SHORT_ADDRESS or ADDR_MODE_EXTENDED_ADDRESS
   */
  command uint8_t getSrcAddrMode(message_t* frame);    

 /**
   * Reads the source address (to be interpreted
   * as specified by the source addressing mode) of the frame.
   *
   * @param frame     the frame
   * @param address   a pointer to where the source address 
   *                  will be written
   * @return          SUCCESS, if the source address is present 
   *                  and was written to "address",
   *                  FAIL otherwise (source address remains
   *                  unmodified)
   */
  command error_t getSrcAddr(message_t* frame, ieee154_address_t *address);   

 /**
   * Reads the source PAN identifier of the frame.
   *
   * @param frame     the frame
   * @param PANID     a pointer to where the source PAN identifier 
   *                  will be written
   * @return          SUCCESS, if the source PAN identifier is present 
   *                  and was written to "PANID", 
   *                  FAIL otherwise (PANID remains unmodified)
   */
  command error_t getSrcPANId(message_t* frame, uint16_t* PANID);  

 /**
   * Returns the destination addressing mode of the frame.
   *
   * @param frame     the frame
   * @return          destination addressing mode of the frame; either
   *                  ADDR_MODE_NOT_PRESENT, ADDR_MODE_RESERVED,
   *                  ADDR_MODE_SHORT_ADDRESS or ADDR_MODE_EXTENDED_ADDRESS
   */
  command uint8_t getDstAddrMode(message_t* frame);    

 /**
   * Reads the destination address (to be interpreted
   * as specified by the destination addressing mode) of the frame.
   *
   * @param frame     the frame
   * @param address   a pointer to where the destination address 
   *                  will be written
   * @return          SUCCESS, if the destination address is present 
   *                  and was written to "address",
   *                  FAIL otherwise (destination address 
   *                  remains unmodified)
   */
  command error_t getDstAddr(message_t* frame, ieee154_address_t *address);   

 /**
   * Reads the destination PAN identifier of the frame.
   *
   * @param PANID     a pointer to where the destination 
   *                  PAN identifier should be written
   * @param frame     the frame
   * @return          SUCCESS, if the destination PAN identifier 
   *                  is present and was copied to "PANID", 
   *                  FAIL otherwise (PANID remains unmodified)
   */
  command error_t getDstPANId(message_t* frame, uint16_t* PANID);  

 /**
   * Sets the addressing fields in the MAC header of a frame. The source 
   * PAN identifier and the source address will be set automatically, their
   * values depend on the <tt>SrcAddrMode</tt> parameter: if 
   * <tt>SrcAddrMode</tt> is a short or extended address, then
   * the current PIB attributes <tt>macShortAddress</tt> or 
   * <tt>aExtendedAddress</tt> and <tt>macPANId</tt> are used.
   *
   * @param frame         the frame
   * @param srcAddrMode   the source addressing mode
   * @param dstAddrMode   the destination addressing mode
   * @param dstPANID      the 16 bit PAN identifier of the destination
   * @param dstAddr       individual device address of the destination as per
   *                      the dstAddrMode
   * @param security      the security options (NULL means security is
   *                      disabled)
   *                      
   * @return          SUCCESS if the addressing fields where written,
   *                  FAIL if an incorrect addressing mode was specified
   */
  command error_t setAddressingFields(message_t* frame,
                          uint8_t SrcAddrMode,
                          uint8_t DstAddrMode,
                          uint16_t DstPANID,
                          ieee154_address_t *DstAddr,
                          ieee154_security_t *security);

 /**
   * Returns a pointer to the MAC payload portion of a frame.
   *
   * @param frame     the frame
   * @return          a pointer to the frame's payload 
   */
  command void* getPayload(message_t* frame);

  /**
    * Returns the length of the MAC payload portion of the frame (in byte). 
    *
    * @param  frame   the frame 
    * @return         the length of the frame's payload (in byte)
    */
  command uint8_t getPayloadLength(message_t* frame);

 /** 
  * Returns the point in time when the first bit (of the PHY preamble) of the
  * frame was received or transmitted. Time is expressed in symbols as local
  * time (which can also be accessed via the LocalTime<T62500hz> interface
  * provided by your platform, e.g.
  * tos/platforms/telosb/mac/tkn154/timer/LocalTime62500hzC).  If
  * <tt>isTimestampValid()</tt> returns FALSE then the timestamp is not valid
  * and must be ignored.
  *
  * @param frame     the frame 
  * @return          timestamp of the frame
  */
  command uint32_t getTimestamp(message_t* frame);  

 /**
   * Tells whether the timestamp is valid.
   *
   * @return          TRUE if timestamp is valid, FALSE otherwise.
   */
  command bool isTimestampValid(message_t* frame);  

 /**
   * Returns the sequence number of the frame.
   *
   * @param frame     the frame
   * @return          sequence number of the frame
   */
  command uint8_t getDSN(message_t* frame);  

 /**
   * Returns the link quality level of a received frame, where
   * "link quality level" is defined in Sect. 6.9.8 of the 
   * IEEE 802.15.4-2006 standard. For the CC2420 radio it is
   * identical with the LQI.
   *
   * @param frame     the frame
   * @return          link quality level 
   */
  command uint8_t getLinkQuality(message_t* frame);  

 /**
   * Returns the average RSSI (in dBm) of a received frame. The 
   * IEEE 802.15.4-2006 standard does not specify that a radio
   * must provide RSSI, so this command is optional: if a
   * radio does not provide per-frame RSSI then this call will 
   * return a value of +127.
   *
   * @param frame     the frame
   * @return          RSSI
   */
  command int8_t getRSSI(message_t* frame);  

  /**
    * Returns the type of the frame
    * BEACON=0, DATA=1, ACK=2, COMMAND=3.
    *
    * Note: For beacon frames one can use the <tt>IEEE154BeaconFrame</tt>
    * interface to inspect additional fields of the frame.
    *
    * @param  frame   the frame
    * @return         the type of the frame
    */
  command uint8_t getFrameType(message_t* frame);

 /**
   * Returns a pointer to the MAC header (i.e. to the first byte of 
   * the Frame Control field).
   *
   * @param frame     the frame
   * @return          a pointer to the frame's header
   */
  command void* getHeader(message_t* frame);

  /**
    * Returns the length of the MAC header.
    *
    * @param  frame   the frame 
    * @return         the length of the MAC header (in byte)
    */
  command uint8_t getHeaderLength(message_t* frame);

  /**
    * Tells whether or not the frame was received while 
    * promiscuous mode was enabled.
    *
    * @param  frame   the frame
    * @return         TRUE if frame was received while in promiscuous
    *                 mode, FALSE otherwise
    */
  command bool wasPromiscuousModeEnabled(message_t* frame);

  /**
    * Tells whether or not the frame has a standard compliant
    * IEEE 802.15.4 header - this will only be relevant for frames 
    * received while in promiscuous mode, because then no filtering
    * (except CRC check) was applied. Note: if this command returns
    * FALSE, then all other commands in this interface (except
    * <tt>wasPromiscuousModeEnabled()</tt>) and the 
    * <tt>IEEE154BeaconFrame</tt> interface return undefined values!
    *
    * @param  frame   the frame
    * @return         TRUE if frame has a standard compliant header,
    *                 FALSE otherwise
    */
  command bool hasStandardCompliantHeader(message_t* frame);

}
