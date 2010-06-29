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

interface Globals
{
  command uint32_t getNumPubPktTrans();
  command void setNumPubPktTrans(uint32_t val);
  command void incNumPubPktTrans();

  command uint32_t getNumRecvPageTrans();
  command void setNumRecvPageTrans(uint32_t val);
  command void incNumRecvPageTrans();

  command uint32_t getAvgPubPktTransTime();
  command void setAvgPubPktTransTime(uint32_t val);

  command uint32_t getAvgRecvPageTransTime();
  command void setAvgRecvPageTransTime(uint32_t val);

  command uint32_t getNumPubPktRetrans();
  command void setNumPubPktRetrans(uint32_t val);
  command void incNumPubPktRetrans();

  command uint32_t getNumPubHSRetrans();
  command void setNumPubHSRetrans(uint32_t val);
  command void incNumPubHSRetrans();

  command uint32_t getNumRecvHSRetrans();
  command void setNumRecvHSRetrans(uint32_t val);
  command void incNumRecvHSRetrans();

  command void* _getStartAddr();
  command uint32_t _getSize();
}
