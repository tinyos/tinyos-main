/*
* Copyright (c) 2009 Johns Hopkins University.
* Copyright (c) 2010 CSIRO Australia
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
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
