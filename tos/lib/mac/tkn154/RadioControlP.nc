/* 
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2009-03-24 12:56:46 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154_MAC.h"
configuration RadioControlP  
{
  provides
  {
    interface RadioRx as RadioRx[uint8_t client];
    interface RadioTx as RadioTx[uint8_t client];
    interface SlottedCsmaCa as SlottedCsmaCa[uint8_t client];
    interface UnslottedCsmaCa as UnslottedCsmaCa[uint8_t client];
    interface RadioOff as RadioOff[uint8_t client];
    interface TransferableResource[uint8_t id];
    interface ResourceRequested[uint8_t id];
  } uses {
    interface RadioRx as PhyRx;
    interface RadioTx as PhyTx;
    interface SlottedCsmaCa as PhySlottedCsmaCa;
    interface UnslottedCsmaCa as PhyUnslottedCsmaCa;
    interface RadioOff as PhyRadioOff;
    interface Get<bool> as RadioPromiscuousMode;
    interface ResourceConfigure[uint8_t id];
    interface Leds;
  }
}
implementation
{
  components RadioControlImplP;
  RadioRx = RadioControlImplP.MacRx;
  RadioTx = RadioControlImplP.MacTx;
  SlottedCsmaCa = RadioControlImplP.SlottedCsmaCa;
  UnslottedCsmaCa = RadioControlImplP.UnslottedCsmaCa;
  RadioOff = RadioControlImplP.MacRadioOff;
  PhyRx = RadioControlImplP.PhyRx;
  PhyTx = RadioControlImplP.PhyTx;
  PhySlottedCsmaCa = RadioControlImplP.PhySlottedCsmaCa;
  PhyUnslottedCsmaCa = RadioControlImplP.PhyUnslottedCsmaCa;
  PhyRadioOff = RadioControlImplP.PhyRadioOff;
  RadioPromiscuousMode = RadioControlImplP;
  Leds = RadioControlImplP;

  components MainC;
  components new RoundRobinResourceQueueC(uniqueCount(IEEE802154_RADIO_RESOURCE)) as Queue;
  components new SimpleTransferArbiterP() as Arbiter;

  MainC.SoftwareInit -> Queue;

  TransferableResource = Arbiter;
  ResourceRequested = Arbiter;
  RadioControlImplP.ArbiterInfo -> Arbiter;
  ResourceConfigure = Arbiter;

  Arbiter.Queue -> Queue;
}
