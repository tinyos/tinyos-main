/* Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

#include "ppp.h"
#include "HdlcFraming.h"

/** Implementation of HDLC-like framing as defined in RFC1662 for PPP.
 *
 * This implementation is optimized to receive data as efficiently as
 * possible.  It does this by maintaining a FragmentPool that allows
 * multiple fragments to be collected in interrupt context while a
 * previous frame is being processed in task context.  Extra bytes
 * inserted for transparency during transmission are stripped while
 * the data is being received, to 
 *
 * @note When used in PPP, it is highly likely that the first frame
 * received after a Configure-Ack that completes the LCP negotiation
 * will fail with a BadCRC.  That Configure-Ack will install a new
 * ACCM indicating that low-value octets are valid data, rather than
 * being corrupted control characters.  The sender of the following
 * frame will assume this ACCM is installed, and will neglect to add
 * transparency escapes for those characters.  Because this component
 * will have already begun processing the incoming data for the frame,
 * but the task that interprets the Configure-Ack and installs the
 * ACCM may not have completed, it is highly likely that some valid
 * data characters will be dropped, resulting in a checksum failure
 * and loss of the frame.  The peer will subsequently retransmit the
 * frame, which will be correctly interpreted because by that point
 * the ACCM will have been updated.  In other words, don't get your
 * knickers all in a twist because the LEDs indicate a BadCRC HDLC
 * error on startup.
 *
 * The implementation uses a local task to process transmission of
 * messages.  Notification of frame transmission occurs in this
 * context.
 *
 * @note You must release all frames signaled by receivedFrame() when
 * you stop this component, including any frames signalled after you
 * began the stop process.
 *
 * @param RX_BUFFER_SIZE Size, in octets, to use for the fragment pool
 * used to hold incoming messages
 *
 * @param RX_FRAME_LIMIT Maximum number of fragments (individual
 * messages) supported by the fragment pool
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */

generic configuration HdlcFramingC (unsigned int RX_BUFFER_SIZE,
                                    uint8_t RX_FRAME_LIMIT) {
  uses {
    interface HdlcUart;
    interface StdControl as UartControl;
  }
  provides {
    interface StdControl;
    interface HdlcFraming;
#if DEBUG_HDLC_FRAMING
    interface DebugHdlcFraming;
#endif /* DEBUG_HDLC_FRAMING */
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
  }
} implementation {
  components new HdlcFramingP(RX_FRAME_LIMIT);
  HdlcUart = HdlcFramingP;
  HdlcFraming = HdlcFramingP;
  HdlcFramingOptions = HdlcFramingP;
  UartControl = HdlcFramingP.UartControl;
  StdControl = HdlcFramingP;
#if DEBUG_HDLC_FRAMING
  DebugHdlcFraming = HdlcFramingP;
#endif /* DEBUG_HDLC_FRAMING */

  /* If the fragment pool doesn't have one more slot than the number
   * of active frames, then if we get into a situation where all the
   * frames are in use the freeze on the last one didn't reclaim any
   * memory, and even as earlier frames are released there may not be
   * enough contiguous space to get another one allocated. */
  components new FragmentPoolC(RX_BUFFER_SIZE, 1+RX_FRAME_LIMIT) as InputFramePoolC;
  HdlcFramingP.InputFramePool -> InputFramePoolC;

  components MainC;
  MainC.SoftwareInit -> HdlcFramingP;
}

