/* Copyright (c) 2011 People Power Co.
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
    interface HdlcUart;
    interface StdControl as UartControl;
    interface DebugDefaultHdlcUart;
  }
  provides {
    interface StdControl as StubSerialControl;
    interface UartStream as StubUartStream;
  }
#include <unittest/module_spec.h>
} implementation {
#include <unittest/module_impl.h>

  enum {
    RingBufferLength = PLATFORM_SERIAL_RX_BUFFER_SIZE,
    LocalBufferLength = 2 * RingBufferLength,
  };

  task void run_tests ();

  int ssc_start_count;
  command error_t StubSerialControl.start ()
  {
    ++ssc_start_count;
    return SUCCESS;
  }
  int ssc_stop_count;
  command error_t StubSerialControl.stop ()
  {
    ++ssc_stop_count;
    return SUCCESS;
  }

  int hu_sendDone_count;
  int hu_sendDone_error;
  async event void HdlcUart.sendDone (error_t error)
  {
    hu_sendDone_error = error;
    ++hu_sendDone_count;
  }

  int postOnEvent;
  int eventCount;
  void checkPostEvent ()
  {
    if (++eventCount == postOnEvent) {
      post run_tests();
    }
    printf("evt %d of %d\n", eventCount, postOnEvent);
  }

  int hu_uartError_count;
  int hu_uartError_error;
  async event void HdlcUart.uartError (error_t error)
  {
    printf("HdlcUart.uartError %d\r\n", error);
    hu_uartError_error = error;
    ++hu_uartError_count;
    checkPostEvent();
  }
  
  uint8_t rxBuffer[LocalBufferLength];
  uint8_t* rxp;

  event void HdlcUart.receivedByte (uint8_t byte)
  {
    printf("HdlcUart.receivedByte 0x%02x\r\n", byte);
    *rxp++ = byte;
    checkPostEvent();
  }

  void hu_resetRxBuffer ()
  {
    eventCount = 0;
    hu_uartError_count = 0;
    rxp = rxBuffer;
  }

  async command error_t StubUartStream.send (uint8_t* buf, uint16_t len) { return FAIL; }
  async command error_t StubUartStream.receive (uint8_t* buf, uint16_t len) { return FAIL; }
  async command error_t StubUartStream.enableReceiveInterrupt () { return FAIL; }
  async command error_t StubUartStream.disableReceiveInterrupt () { return FAIL; }

  void testStartup ()
  {
    error_t rc;
    uint8_t* ring_buffer;
    
    ASSERT_EQUAL(RingBufferLength, call DebugDefaultHdlcUart.ringBufferLength());
    ring_buffer = call DebugDefaultHdlcUart.ringBuffer();
    ASSERT_TRUE(!! ring_buffer);
    ASSERT_EQUAL_PTR(0, call DebugDefaultHdlcUart.rbStore());
    ASSERT_EQUAL_PTR(0, call DebugDefaultHdlcUart.rbLoad());

    ASSERT_EQUAL(0, ssc_start_count);
    rc = call UartControl.start();
    ASSERT_EQUAL(1, ssc_start_count);
    ASSERT_EQUAL(SUCCESS, rc);

    ASSERT_EQUAL_PTR(ring_buffer, call DebugDefaultHdlcUart.rbStore());
    ASSERT_EQUAL_PTR(ring_buffer, call DebugDefaultHdlcUart.rbLoad());
  }

  void testFillBuffer_pre (int size)
  {
    uint8_t* ring_buffer = call DebugDefaultHdlcUart.ringBuffer();
    int ring_buffer_length = call DebugDefaultHdlcUart.ringBufferLength();
    int ring_buffer_capacity = ring_buffer_length - 1;
    uint8_t* rb_start;
    uint8_t* rbs;
    uint8_t* rbl;
    int pending;
    int i;
    
    hu_resetRxBuffer();
    ASSERT_EQUAL_PTR(rxp, rxBuffer);
    ASSERT_EQUAL(0, hu_uartError_count);

    /* Resume testing once all the data has been fed in.  Can't just
     * post here, since it may take two invocations of the feeder task
     * to process everything if the loaded data wraps around the ring
     * buffer.  NOTE: Set this now; error events occur in this
     * call. */
    postOnEvent = size;

    rb_start = call DebugDefaultHdlcUart.rbStore();
    ASSERT_EQUAL_PTR(rb_start, call DebugDefaultHdlcUart.rbLoad());

    printf("Fill buffer with %d elements\n", size);
    for (i = 0; i < size; ++i) {
      signal StubUartStream.receivedByte('A' + i);
    }

    rbs = call DebugDefaultHdlcUart.rbStore();
    ASSERT_TRUE(ring_buffer <= rbs);
    ASSERT_TRUE(rbs < ring_buffer + ring_buffer_length);
    if (rbs >= rb_start) {
      pending = rbs - rb_start;
    } else {
      pending = (ring_buffer + ring_buffer_length - rb_start) + (rbs - ring_buffer);
    }

    if (size <= ring_buffer_capacity) {
      ASSERT_EQUAL(0, hu_uartError_count);
      ASSERT_EQUAL_PTR(rb_start, call DebugDefaultHdlcUart.rbLoad());
    } else {
      /* On error for each character over the capacity */
      ASSERT_EQUAL(size - ring_buffer_capacity, hu_uartError_count);
      /* Make sure those errors were counted as events */
      ASSERT_EQUAL(eventCount, hu_uartError_count);
      /* Make sure the system is in an error state */
      ASSERT_EQUAL_PTR(0, call DebugDefaultHdlcUart.rbLoad());
      /* Fake events for the data that got thrown away */
      eventCount += ring_buffer_capacity;

      /* Wake up on the event that indicates resynchronization. */
      ASSERT_EQUAL(eventCount, postOnEvent);
      ++postOnEvent;
    }

  }

  void testFillBuffer_post (int size)
  {
    int ring_buffer_length = call DebugDefaultHdlcUart.ringBufferLength();
    int ring_buffer_capacity = ring_buffer_length - 1;

    printf("Validating fill %d\r\n", size);
    if (size <= ring_buffer_capacity) {
      ASSERT_EQUAL(size, rxp - rxBuffer);
    } else {
      ASSERT_EQUAL(0, rxp - rxBuffer);
    }
  }

  int test_stage;
  task void run_tests ()
  {
    switch (++test_stage) {
    default:
      ASSERT_TRUE(! "Unrecognized test stage");
      break;
    case 1:
      testStartup();
      testFillBuffer_pre(1);
      break;
    case 2:
      testFillBuffer_post(1);
      testFillBuffer_pre(RingBufferLength / 2);
      break;
    case 3:
      testFillBuffer_post(RingBufferLength / 2);
      testFillBuffer_pre(RingBufferLength - 1);
      break;
    case 4:
      testFillBuffer_post(RingBufferLength - 1);
      testFillBuffer_pre(RingBufferLength);
      break;
    case 5:
      testFillBuffer_post(RingBufferLength);
      testFillBuffer_pre(2 * RingBufferLength);
      break;
    case 6:
      testFillBuffer_post(2 * RingBufferLength);
      //FALLTHRU
      ALL_TESTS_PASSED();
      break;
    }
  }

  event void Boot.booted () {
    post run_tests();
  }
}
