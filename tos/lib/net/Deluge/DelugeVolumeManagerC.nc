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

configuration DelugeVolumeManagerC
{
  provides interface DelugeVolumeManager[uint8_t client];
}

implementation
{
  components DelugeVolumeManagerP;

  DelugeVolumeManager = DelugeVolumeManagerP;

  components new BlockWriterC(VOLUME_DELUGE1) as BlockWriterDeluge1;
  components new BlockWriterC(VOLUME_DELUGE2) as BlockWriterDeluge2;
  components new BlockWriterC(VOLUME_DELUGE3) as BlockWriterDeluge3;

  DelugeVolumeManagerP.BlockWrite[VOLUME_DELUGE1] -> BlockWriterDeluge1;
  DelugeVolumeManagerP.BlockWrite[VOLUME_DELUGE2] -> BlockWriterDeluge2;
  DelugeVolumeManagerP.BlockWrite[VOLUME_DELUGE3] -> BlockWriterDeluge3;

  DelugeVolumeManagerP.Resource[VOLUME_DELUGE1] -> BlockWriterDeluge1;
  DelugeVolumeManagerP.Resource[VOLUME_DELUGE2] -> BlockWriterDeluge2;
  DelugeVolumeManagerP.Resource[VOLUME_DELUGE3] -> BlockWriterDeluge3;
}
