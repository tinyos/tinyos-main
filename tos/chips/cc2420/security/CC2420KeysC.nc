/*
* Copyright (c) 2008 Johns Hopkins University.
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
 * @author Razvan Musaloiu-E.
 * @author Jong Hyun Lim
 */

configuration CC2420KeysC
{
  provides interface CC2420Keys;
}

implementation
{
  components new CC2420SpiC();
  components HplCC2420PinsC as Pins;
  components CC2420KeysP;

  CC2420Keys = CC2420KeysP;

  CC2420KeysP.CSN -> Pins.CSN;
  CC2420KeysP.KEY0 -> CC2420SpiC.KEY0;
  CC2420KeysP.KEY1 -> CC2420SpiC.KEY1;
  CC2420KeysP.Resource -> CC2420SpiC.Resource;
}
