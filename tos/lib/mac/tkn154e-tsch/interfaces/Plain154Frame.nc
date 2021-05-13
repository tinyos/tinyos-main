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
 * Based on lib/mac/tkn154/interfaces/public/IEEE154Frame.nc (Revision 1.3)
 * by Jan Hauer.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * The IEEE154Frame interface allows to access the content of a IEEE 802.15.4
 * frame.
 */

#include "plain154_types.h"
#include "plain154_message_structs.h"
#include "message.h"

interface Plain154Frame
{

 /**
   * Returns the source addressing mode of the frame.
   *
   * @param header    the header of the frame
   * @return          source addressing mode of the frame; either
   *                  PLAIN154_ADDR_NOT_PRESENT, PLAIN154_ADDR_SIMPLE,
   *                  PLAIN154_ADDR_SHORT or PLAIN154_ADDR_EXTENDED
   */
  async command uint8_t getSrcAddrMode(plain154_header_t* header);

 /**
   * Reads the source address (to be interpreted
   * as specified by the source addressing mode) of the frame.
   *
   * @param header    the header of the frame
   * @param address   a pointer to where the source address
   *                  will be written
   * @return          SUCCESS, if the source address is present
   *                  and was written to "address",
   *                  FAIL otherwise (source address remains
   *                  unmodified)
   */
  async command error_t getSrcAddr(plain154_header_t* header, plain154_address_t *address);

 /**
   * Reads the source PAN identifier of the frame.
   *
   * @param header    the header of the frame
   * @param PANID     a pointer to where the source PAN identifier
   *                  will be written
   * @return          SUCCESS, if the source PAN identifier is present
   *                  and was written to "PANID",
   *                  FAIL otherwise (PANID remains unmodified)
   */
  async command error_t getSrcPANId(plain154_header_t* header, uint16_t* PANID);

 /**
   * Returns the destination addressing mode of the frame.
   *
   * @param header    the header of the frame
   * @return          destination addressing mode of the frame; either
   *                   PLAIN154_ADDR_NOT_PRESENT, PLAIN154_ADDR_SIMPLE,
   *                   PLAIN154_ADDR_SHORT or PLAIN154_ADDR_EXTENDED
   */
  async command uint8_t getDstAddrMode(plain154_header_t* header);

 /**
   * Reads the destination address (to be interpreted
   * as specified by the destination addressing mode) of the frame.
   *
   * @param header    the header of the frame
   * @param address   a pointer to where the destination address
   *                   will be written
   * @return          SUCCESS, if the destination address is present
   *                   and was written to "address",
   *                   FAIL otherwise (destination address
   *                   remains unmodified)
   */
  async command error_t getDstAddr(plain154_header_t* header, plain154_address_t *address);

 /**
   * Reads the destination PAN identifier of the frame.
   *
   * @param PANID     a pointer to where the destination
   *                   PAN identifier should be written
   * @param header    the header of the frame
   * @return          SUCCESS, if the destination PAN identifier
   *                   is present and was copied to "PANID",
   *                   FAIL otherwise (PANID remains unmodified)
   */
  async command error_t getDstPANId(plain154_header_t* header, uint16_t* PANID);

 /**
   * Sets the addressing fields in the MAC header of a frame.
   *
   * @param header         the header of the frame
   * @param srcAddrMode    the source addressing mode (PLAIN154_ADDR_{NOT_PRESENT, SIMPLE, SHORT, EXTENDED})
   * @param dstAddrMode    the destination addressing mode (PLAIN154_ADDR_{NOT_PRESENT, SIMPLE, SHORT, EXTENDED})
   * @param srcPANID       the 16 bit PAN identifier of the source
   * @param dstPANID       the 16 bit PAN identifier of the destination
   * @param srcAddr        individual device address of the source as per
   *                        the srcAddrMode
   * @param dstAddr        individual device address of the destination as per
   *                        the dstAddrMode
   * @param frameVersion   the frame version
   * @param compressPanId  Only for frame version 2: use PAN ID
   *                        compression if possible, ignored otherwise
   *
   * @return          SUCCESS if the addressing fields where written,
   *                   FAIL if an incorrect addressing mode was specified
   */
  async command error_t setAddressingFields(plain154_header_t* header,
                          uint8_t srcAddrMode,
                          uint8_t dstAddrMode,
                          uint16_t srcPANID,
                          uint16_t dstPANID,
                          plain154_address_t *srcAddr,
                          plain154_address_t *dstAddr,
                          uint8_t frameVersion,
                          bool compressPanId);

 /**
   * Returns the sequence number of the frame.
   *
   * @param header    the header of the frame
   * @return          sequence number of the frame
   */
  async command uint8_t getDSN(plain154_header_t* header);

 /**
   * Sets the sequence number of the frame.
   *
   * @param header    the header of the frame
   * @param dsn       sequence number of the frame
   */
  async command void setDSN(plain154_header_t* header, uint8_t dsn);

 /**
   * Returns the frame version of a frame.
   * PLAIN154_FRAMEVERSION_0 (2003), PLAIN154_FRAMEVERSION_1 (2006),
   * PLAIN154_FRAMEVERSION_2 (2011)
   *
   * @param header    the header of the frame
   * @return          the frame version
   */
  async command uint8_t getFrameVersion(plain154_header_t* header);

 /**
   * Sets the frame version of a frame.
   * PLAIN154_FRAMEVERSION_0 (2003), PLAIN154_FRAMEVERSION_1 (2006),
   * PLAIN154_FRAMEVERSION_2 (2011)
   *
   * @param header    the header of the frame
   * @param version   the frame version
   */
  async command void setFrameVersion(plain154_header_t* header, uint8_t version);

 /**
   * Returns the status of the ACK request flag of a frame.
   *
   * @param header    the header of the frame
   * @return          TRUE if frame has ACK request flag set
   *                  mode, FALSE otherwise
   */
  async command bool isAckRequested(plain154_header_t* header);

 /**
   * Sets the status of the ACK request flag of a frame.
   *
   * @param header    the header of the frame
   * @param ack_req   TRUE if an ACK shall be sent
   *                  FALSE otherwise
   */
  async command void setAckRequest(plain154_header_t* header, bool ack_req);

 /**
   * Returns the type of the frame
   * PLAIN154_FRAMETYPE_{BEACON,DATA,ACK,CMD,LLDN,MULTIPURPOSE}
   *
   * @param header    the header of the frame
   * @return          the type of the frame
   */
  async command uint8_t getFrameType(plain154_header_t* header);

 /**
   * Sets the type of the frame
   * PLAIN154_FRAMETYPE_{BEACON,DATA,ACK,CMD,LLDN,MULTIPURPOSE}
   *
   * @param header    the header of the frame
   * @param type      the type of the frame
   */
  async command void setFrameType(plain154_header_t* header, uint8_t type);

 /**
   * Returns a pointer to the MAC header
   *
   * @param frame     the frame
   * @return          a pointer to the frame's header
   */
  async command plain154_header_t* getHeader(message_t* frame);

 /**
   * Fills a plain154_header_hints_t struct with information of the presence of
   * MAC header fields.
   *
   * @param frame     the frame
   * @param hints     a pointer to the header hints
   * @return          FAIL in case of an error and SUCCESS otherwise
   */
  async command error_t getHeaderHints(plain154_header_t* header, plain154_header_hints_t *hints);

 /**
   * Returns the length the MAC header would have on air.
   * Assumes that frame is completely set up.
   *
   * @param header    the header of the frame
   * @return          the length of the MAC header (in byte)
   */
  async command error_t getActualHeaderLength(plain154_header_t* header, uint8_t *length);

 /**
   * Tells whether or not the frame uses PAN ID compression.
   *
   * @param header    the header of the frame
   * @return          TRUE if frame uses PAN ID compression
   *                  mode, FALSE otherwise
   */
  async command bool hasPanidCompression(plain154_header_t* header);

 /**
   * Tells whether or not a frame is pending.
   *
   * @param header    the header of the frame
   * @return          TRUE if a frame is pending
   *                  FALSE otherwise
   */
  async command bool isFramePending(plain154_header_t* header);

 /**
   * Sets whether or not a frame is pending.
   *
   * @param header    the header of the frame
   * @param pending   TRUE if a frame is pending
   *                  FALSE otherwise
   */
  async command void setFramePending(plain154_header_t* header, bool pending);

  /**
   * Tells whether or not an IE list is present.
   *
   * @param header    the header of the frame
   * @return          TRUE if an IE list is present
   *                  FALSE otherwise
   */
  async command bool isIEListPresent(plain154_header_t* header);

 /**
   * Sets whether or not an IE list is present.
   *
   * @param header    the header of the frame
   * @param IEList    TRUE if an IE list is present
   *                  FALSE otherwise
   */
  async command void setIEListPresent(plain154_header_t* header, bool IEList);
}
