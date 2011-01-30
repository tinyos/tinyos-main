/*
* Copyright (c) 2009 Johns Hopkins University.
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
 */

configuration Sam3uDmaC {
  provides interface Sam3uDmaControl as Control;
  provides interface Sam3uDmaChannel as Channel0;
  provides interface Sam3uDmaChannel as Channel1;
  provides interface Sam3uDmaChannel as Channel2;
  provides interface Sam3uDmaChannel as Channel3;
}

implementation {
  components new Sam3uDmaChannelP() as Channel0P;
  components new Sam3uDmaChannelP() as Channel1P;
  components new Sam3uDmaChannelP() as Channel2P;
  components new Sam3uDmaChannelP() as Channel3P;
  components Sam3uDmaControlP as ControlP;
  components HplSam3uDmaC as DmaC;

  Control = ControlP;
  Channel0 = Channel0P;
  Channel1 = Channel1P;
  Channel2 = Channel2P;
  Channel3 = Channel3P;

  ControlP.DmaControl -> DmaC;
  //ControlP.DmaChannel0 -> DmaC.Channel0;
  //ControlP.DmaChannel1 -> DmaC.Channel1;
  //ControlP.DmaChannel2 -> DmaC.Channel2;
  //ControlP.DmaChannel3 -> DmaC.Channel3;

  Channel0P.DmaChannel -> DmaC.Channel0;
  Channel1P.DmaChannel -> DmaC.Channel1;
  Channel2P.DmaChannel -> DmaC.Channel2;
  Channel3P.DmaChannel -> DmaC.Channel3;

}
