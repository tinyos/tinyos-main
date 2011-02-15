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

#ifndef OIP_TEST_UNITTEST_MODULE_IMPL_H_
#define OIP_TEST_UNITTEST_MODULE_IMPL_H_

  char messageBuffer_[64];
  void fail (const char* msg)
  {
    call FailLed.on();
    while (1) {
      volatile uint16_t ctr = 0x8000;
      printf("%s\r\n", msg);
      while (--ctr);
    }
  }

#define ASSERT_EQUAL_PTR(_v1, _v2) { \
  const void* v1 = (const void*)_v1;          \
  const void* v2 = (const void*)_v2;          \
  if (v1 != v2) { \
    sprintf(messageBuffer_, "FAIL[%d]: %p != %p (%s != %s)", __LINE__, v1, v2, #_v1, #_v2); \
    fail(messageBuffer_); \
  } \
  printf("Pass: %s == %s (%p)\r\n", #_v1, #_v2, v1); \
}

#define ASSERT_EQUAL(_v1, _v2) { \
  int v1 = _v1; \
  int v2 = _v2; \
  if (v1 != v2) { \
    sprintf(messageBuffer_, "FAIL[%d]: %d != %d (%s != %s)", __LINE__, v1, v2, #_v1, #_v2); \
    fail(messageBuffer_); \
  } \
  printf("Pass: %s == %s (%d)\r\n", #_v1, #_v2, v1); \
}

#define ASSERT_EQUAL_32(_v1, _v2) { \
  int32_t v1 = _v1; \
  int32_t v2 = _v2; \
  if (v1 != v2) { \
    sprintf(messageBuffer_, "FAIL[%d]: %ld != %ld (%s != %s)", __LINE__, v1, v2, #_v1, #_v2); \
    fail(messageBuffer_); \
  } \
  printf("Pass: %s == %s (%ld)\r\n", #_v1, #_v2, v1); \
}

#define ASSERT_EQUAL_U32(_v1, _v2) { \
  uint32_t v1 = _v1; \
  uint32_t v2 = _v2; \
  if (v1 != v2) { \
    sprintf(messageBuffer_, "FAIL[%d]: %lu != %lu (%s != %s)", __LINE__, v1, v2, #_v1, #_v2); \
    fail(messageBuffer_); \
  } \
  printf("Pass: %s == %s (%lu)\r\n", #_v1, #_v2, v1); \
}

#define ASSERT_TRUE(_p) { \
  bool p = _p; \
  if (! p) { \
    sprintf(messageBuffer_, "FAIL[%d]: %s is false", __LINE__, #_p); \
    fail(messageBuffer_); \
  } \
  printf("Pass: %s\r\n", #_p); \
}

#define ALL_TESTS_PASSED() do { \
  call PassLed.on(); \
  printf("All tests passed\r\n"); \
  while(1); \
} while (0)

#endif /* OIP_TEST_UNITTEST_MODULE_IMPL_H_ */
