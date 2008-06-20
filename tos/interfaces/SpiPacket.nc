// $Id: SpiPacket.nc,v 1.7 2008-06-20 21:39:09 idgay Exp $

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
 */

/**
 * SPI Packet/buffer interface for sending data over an SPI bus.  This
 * interface provides a split-phase send command which can be used for
 * sending, receiving or both. It is a "send" command because reading
 * from the SPI requires writing bytes. The send call allows NULL
 * parameters for receive or send only operations. This interface is
 * for buffer based transfers where the microcontroller is the master
 * (clocking) device.
 *
 * Often, an SPI bus must first be acquired using a Resource interface
 * before sending commands with SPIPacket. In the case of multiple
 * devices attached to a single SPI bus, chip select pins are often also
 * used.
 *
 * @author Philip Levis
 * @author Jonathan Hui
 * @author Joe Polastre
 * Revision:  $Revision: 1.7 $
 */
interface SpiPacket {

  /**
   * Send a message over the SPI bus.
   *
   * @param 'uint8_t* COUNT_NOK(len) txBuf' A pointer to the buffer to send over the bus. If this
   *              parameter is NULL, then the SPI will send zeroes.
   * @param 'uint8_t* COUNT_NOK(len) rxBuf' A pointer to the buffer where received data should
   *              be stored. If this parameter is NULL, then the SPI will
   *              discard incoming bytes.
   * @param len   Length of the message.  Note that non-NULL rxBuf and txBuf
   *              parameters must be AT LEAST as large as len, or the SPI
   *              will overflow a buffer.
   *
   * @return SUCCESS if the request was accepted for transfer
   */
  async command error_t send( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len );

  /**
   * Notification that the send command has completed.
   *
   * @param 'uint8_t* COUNT_NOK(len) txBuf' The buffer used for transmission
   * @param 'uint8_t* COUNT_NOK(len) rxBuf' The buffer used for reception
   * @param len    The request length of the transfer, but not necessarily
   *               the number of bytes that were actually transferred
   * @param error  SUCCESS if the operation completed successfully, FAIL
   *               otherwise
   */
  async event void sendDone( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len,
                             error_t error );

}
