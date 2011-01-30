/*
 * Copyright (c) 2009 Johns Hopkins University.
 * Copyright (c) 2010 CSIRO Australia
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 * @author Kevin Klues
 */

configuration HplSam3uTwiC {
  provides {
    interface HplSam3uTwiInterrupt as HplSam3uTwiInterrupt0;
    interface HplSam3uTwiInterrupt as HplSam3uTwiInterrupt1;
    interface HplSam3uTwi as HplSam3uTwi0;
    interface HplSam3uTwi as HplSam3uTwi1;
  }
}
implementation{

  enum {
    CLIENT_ID = unique( SAM3U_HPLTWI_RESOURCE ),
  };

  components HplSam3uTwiP as TwiP;
  
  HplSam3uTwiInterrupt0 = TwiP.HplSam3uTwiInterrupt0;
  HplSam3uTwiInterrupt1 = TwiP.HplSam3uTwiInterrupt1;
  HplSam3uTwi0 = TwiP.HplSam3uTwi0;
  HplSam3uTwi1 = TwiP.HplSam3uTwi1;
}
