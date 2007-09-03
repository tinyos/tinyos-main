/*
 * Copyright (c) 2007 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date July 24, 2007
 */

generic module SampleLogReaderP(typedef sample_type_t) {
  provides {
    interface SampleLogRead<sample_type_t>;
  }
  uses {
    interface LogRead;
    interface LogWrite;
  }
}
implementation {
  sample_type_t sample;
  storage_cookie_t writeLocation;

  command error_t SampleLogRead.readFirst() {
    return call LogRead.seek(SEEK_BEGINNING);
  }

  command error_t SampleLogRead.readNext() {
    atomic writeLocation = call LogWrite.currentOffset();
    if(call LogRead.currentOffset() == writeLocation)
      return ECANCEL;
    else return call LogRead.read(&sample, sizeof(sample));
  }

  event void LogRead.readDone(void* buf, storage_len_t len, error_t error) {
    signal SampleLogRead.readDone((sample_type_t*)buf, error);
  }

  event void LogRead.seekDone(error_t error) {
    if(error == SUCCESS) {
      error = call SampleLogRead.readNext();
      if(error != SUCCESS)
        signal SampleLogRead.readDone(&sample, error);
    }
    else signal SampleLogRead.readDone(&sample, error);
  }
  event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t error) {}
  event void LogWrite.eraseDone(error_t error) {}
  event void LogWrite.syncDone(error_t error) {}
  default event void SampleLogRead.readDone(sample_type_t* s, error_t error) {}
}

