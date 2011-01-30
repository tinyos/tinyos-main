/*
 * Copyright (c) 2009 Johns Hopkins University.
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
