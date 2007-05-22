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

generic module FakeBlockReaderC(uint32_t size)
{
  provides interface BlockRead;
}

implementation
{
  enum {
    S_IDLE,
    S_BUSY
  };

  storage_addr_t saddr;
  uint8_t *oribuf;
  uint8_t *sbuf;
  storage_len_t slen;
  uint8_t state = S_IDLE;

  task void task_read()
  {
    while (slen > 0) {
      *sbuf = saddr & 0xFF;
      saddr++;
      sbuf++;
      slen--;
    }

    signal BlockRead.readDone(saddr, oribuf, slen, SUCCESS);
    state = S_IDLE;
  }

  command error_t BlockRead.read(storage_addr_t addr,
				 void* buf,
				 storage_len_t len)
  {
    if (state != S_IDLE) {
      return FAIL;
    }


    state = S_BUSY;
    saddr = addr;
    sbuf = buf;
    oribuf = buf;
    slen = len;
    post task_read();
    return SUCCESS;
  };

  task void task_computeCRC()
  {
    signal BlockRead.computeCrcDone(saddr, slen, 0, SUCCESS);
  }

  command error_t BlockRead.computeCrc(storage_addr_t addr,
				       storage_len_t len,
				       uint16_t crc)
  {
    saddr = addr;
    slen = len;
    post task_computeCRC();
    return SUCCESS;
  }

  command storage_len_t BlockRead.getSize()
  {
    return size;
  }
}
