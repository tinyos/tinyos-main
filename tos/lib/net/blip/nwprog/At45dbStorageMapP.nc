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
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module At45dbStorageMapP
{
  provides {
    interface StorageMap[uint8_t volume_id];
  }
  uses {
    interface At45dbVolume[volume_id_t volume_id];
  }
}

implementation
{
  command storage_addr_t StorageMap.getPhysicalAddress[uint8_t volume_id](storage_addr_t addr)
  {
    storage_addr_t p_addr = 0xFFFFFFFF;
    at45page_t page = call At45dbVolume.remap[volume_id]((addr >> AT45_PAGE_SIZE_LOG2));
    at45pageoffset_t offset = addr & ((1 << AT45_PAGE_SIZE_LOG2) - 1);
    p_addr = page;
    p_addr = p_addr << AT45_PAGE_SIZE_LOG2;
    p_addr += offset;
    return p_addr;
  }
}
