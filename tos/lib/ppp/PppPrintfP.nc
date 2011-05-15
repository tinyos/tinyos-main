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
#include "PppPrintf.h"

#include <stdio.h>

/** Implement putchar() in a way that transfers the data in packets
 * over PPP. */
module PppPrintfP {
  provides {
    interface PppProtocol;
    interface Putchar;
  }
  uses {
    interface Ppp;
  }
} implementation {

  bool disabled__;

  enum {
    Protocol = PppProtocol_Printf,
  };

#if 255 >= PPP_PRINTF_MAX_BUFFER
  typedef uint8_t bufferIndex_t;
#else /* PPP_PRINTF_MAX_BUFFER */
  typedef uint16_t bufferIndex_t;
#endif /* PPP_PRINTF_MAX_BUFFER */
  char buffer_[PPP_PRINTF_MAX_BUFFER];
  bufferIndex_t bufferIndex_;
  frame_key_t activeKey_;

  task void sendBuffer_task ()
  {
    const uint8_t* fpe;
    frame_key_t key;
    uint8_t* fp;
    unsigned int tx_length;
    error_t rc;

    if (activeKey_) {
      return;
    }
    fp = call Ppp.getOutputFrame(Protocol, &fpe, FALSE, &key);
    if (fp == 0) {
      post sendBuffer_task();
      return;
    }

    atomic {
      tx_length = fpe - fp - 1;
      if (bufferIndex_ < tx_length) {
        tx_length = bufferIndex_;
      }
      *fp++ = tx_length;
      memmove(fp, buffer_, tx_length);
      fp += tx_length;
      bufferIndex_ -= tx_length;
      if (0 < bufferIndex_) {
        memcpy(buffer_, buffer_ + tx_length, bufferIndex_);
      }
    }
    rc = call Ppp.fixOutputFrameLength(key, fp);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }
    if (SUCCESS == rc) {
      activeKey_ = key;
    }
  }

  command unsigned int PppProtocol.getProtocol () { return Protocol; }
  command error_t PppProtocol.process (const uint8_t* information,
                                       unsigned int information_length)
  {
    return FAIL;
  }
  command error_t PppProtocol.rejectedByPeer (const uint8_t* data,
                                              const uint8_t* data_end)
  {
    /* If we've been fed a rejected message, disable this protocol. */
    atomic disabled__ = (0 != data);
    return SUCCESS;
  }

  event void Ppp.outputFrameTransmitted (frame_key_t key,
                                         error_t err)
  {
    atomic {
      if (activeKey_ == key) {
        activeKey_ = 0;
        if ((! disabled__) && (0 < bufferIndex_)) {
          post sendBuffer_task();
        }
      }
    }
  }

#undef putchar
  command int Putchar.putchar (int c)
  {
    atomic {
      if ((! disabled__) && (bufferIndex_ < sizeof(buffer_))) {
        buffer_[bufferIndex_++] = c;
        post sendBuffer_task();
      }
    }
    return c;
  }
  
}
