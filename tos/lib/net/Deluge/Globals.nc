/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
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
