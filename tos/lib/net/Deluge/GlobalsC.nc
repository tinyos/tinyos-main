/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

module GlobalsC
{
  provides interface Globals;
}

implementation
{
  struct {
    uint32_t NumPubPktTrans;
    uint32_t NumRecvPageTrans;
    uint32_t AvgPubPktTransTime;
    uint32_t AvgRecvPageTransTime;
    uint32_t NumPubPktRetrans;
    uint32_t NumPubHSRetrans;
    uint32_t NumRecvHSRetrans;
  } _g = {0, 0, 0, 0, 0, 0, 0};

  command uint32_t Globals.getNumPubPktTrans() { return _g.NumPubPktTrans; }
  command void Globals.setNumPubPktTrans(uint32_t val) { _g.NumPubPktTrans = val; }
  command void Globals.incNumPubPktTrans() { _g.NumPubPktTrans++; }

  command uint32_t Globals.getNumRecvPageTrans() { return _g.NumRecvPageTrans; }
  command void Globals.setNumRecvPageTrans(uint32_t val) { _g.NumRecvPageTrans = val; }
  command void Globals.incNumRecvPageTrans() { _g.NumRecvPageTrans++; }

  command uint32_t Globals.getAvgPubPktTransTime() { return _g.AvgPubPktTransTime; }
  command void Globals.setAvgPubPktTransTime(uint32_t val) { _g.AvgPubPktTransTime = val; }

  command uint32_t Globals.getAvgRecvPageTransTime() { return _g.AvgRecvPageTransTime; }
  command void Globals.setAvgRecvPageTransTime(uint32_t val) { _g.AvgRecvPageTransTime = val; }

  command uint32_t Globals.getNumPubPktRetrans() { return _g.NumPubPktRetrans; }
  command void Globals.setNumPubPktRetrans(uint32_t val) { _g.NumPubPktRetrans = val; }
  command void Globals.incNumPubPktRetrans() { _g.NumPubPktRetrans++; }

  command uint32_t Globals.getNumPubHSRetrans() { return _g.NumPubHSRetrans; }
  command void Globals.setNumPubHSRetrans(uint32_t val) { _g.NumPubHSRetrans = val; }
  command void Globals.incNumPubHSRetrans() { _g.NumPubHSRetrans++; }

  command uint32_t Globals.getNumRecvHSRetrans() { return _g.NumRecvHSRetrans; }
  command void Globals.setNumRecvHSRetrans(uint32_t val) { _g.NumRecvHSRetrans = val; }
  command void Globals.incNumRecvHSRetrans() { _g.NumRecvHSRetrans++; }

  command void* Globals._getStartAddr() { return &_g; }
  command uint32_t Globals._getSize() { return sizeof(_g); }
}
