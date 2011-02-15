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

#include <stdio.h>

module TestP {
  uses {
    interface Boot;
    interface PseudoSerial;
    interface StdControl as HdlcControl;
    interface HdlcFraming;
    interface DebugHdlcFraming;
    interface Alarm<TMilli, uint32_t> as KickMe;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  const HdlcRxFrame_t* rxFrames_;
  const HdlcRxFrame_t* rxFrameEnd_;

  const uint8_t* frames[8];
  unsigned int frameLengths[8];
  uint8_t frameIdx;
  uint8_t testCase_;

  task void kickTestCase_task ();

  void dumpRxFrame (const HdlcRxFrame_t* fp)
  {
    printf("RX %d: %p %p state %d\r\n",
           fp-rxFrames_, fp->start, fp->end, fp->frame_state);
  }

  void dumpRxFrames ()
  {
    const HdlcRxFrame_t* fp = rxFrames_;
    while (fp < rxFrameEnd_) {
      dumpRxFrame(fp++);
    }
  }

  task void kickTestCase_task();

  event void HdlcFraming.sendDone (const uint8_t* data,
                                   unsigned int len,
                                   error_t err) { }

  event void HdlcFraming.receivedFrame (const uint8_t* data,
                                        unsigned int len)
  {
    frames[frameIdx] = data;
    frameLengths[frameIdx] = len;
    ++frameIdx;
    post kickTestCase_task();
  }

  async event void KickMe.fired () { post kickTestCase_task(); }

  async event void HdlcFraming.receivedDelimiter () { }

  async event void HdlcFraming.receptionError (HdlcError_e code) { }

  unsigned int stage_;

  task void testCase0_task ()
  {
    switch (stage_++) {
      case 0:
        ASSERT_EQUAL(RFS_receiving, rxFrames_[0].frame_state);
        call PseudoSerial.feedUartStream("\x7e\xff\x7d\x23\x61\xd8\x58\x7e", 8);
        break;
      case 1:
        ASSERT_EQUAL(RFS_processing, rxFrames_[0].frame_state);
        ASSERT_EQUAL(RFS_receiving, rxFrames_[1].frame_state);
        call PseudoSerial.feedUartStream("\xff\x7d\x23\x61\xd8\x58\x7e", 7);
        break;
      case 2:
        ASSERT_EQUAL(RFS_processing, rxFrames_[0].frame_state);
        call HdlcFraming.releaseReceivedFrame(frames[0]);
        ASSERT_EQUAL(RFS_releasable, rxFrames_[0].frame_state);
        post kickTestCase_task();
        break;
      case 3:
        ASSERT_EQUAL(RFS_unused, rxFrames_[0].frame_state);
        call HdlcFraming.releaseReceivedFrame(frames[1]);
        post kickTestCase_task();
        break;
      default:
        ++testCase_;
        post kickTestCase_task();
        break;
    }
  }
  task void kickTestCase_task ()
  {
    printf("TC %d S %d\r\n", testCase_, stage_);
    dumpRxFrames();
    switch (testCase_) {
      case 0:
        post testCase0_task();
        break;
      default:
        ALL_TESTS_PASSED();
        //NOTREACHED
        break;
    }
  }

  void startTestCase (int test_case)
  {
    stage_ = 0;
    testCase_ = test_case;
    post kickTestCase_task();
  }

  event void Boot.booted () {
    printf("Booted\r\n");
    rxFrames_ = call DebugHdlcFraming.rxFrames();
    rxFrameEnd_ = rxFrames_ + call DebugHdlcFraming.numRxFrames();
    call HdlcControl.start();
    dumpRxFrames();
    startTestCase(0);
  }
}
