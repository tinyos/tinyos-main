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
 * $Date: 2009-05-18 12:54:11 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154.h"
configuration Ieee802154NonBeaconEnabledC
{
  provides
  {
    // MCPS-SAP
    interface MCPS_DATA;
    interface MCPS_PURGE;

    // MLME-SAP
    interface MLME_ASSOCIATE;
    interface MLME_BEACON_NOTIFY;
    interface MLME_COMM_STATUS;
    interface MLME_DISASSOCIATE;
    interface MLME_GET;
    interface MLME_ORPHAN;
    interface MLME_POLL;
    interface MLME_RESET;
    interface MLME_RX_ENABLE;
    interface MLME_SCAN;
    interface MLME_SET;
    interface MLME_START;
    interface IEEE154Frame;
    interface IEEE154BeaconFrame;
    interface IEEE154TxBeaconPayload;
    interface SplitControl as PromiscuousMode;
    interface Get<uint64_t> as LocalExtendedAddress;
    interface Timestamp;
    interface Packet;
  }
}
implementation
{
  components TKN154NonBeaconEnabledP as MAC;

  MLME_START = MAC;
  MLME_GET = MAC;
  MLME_SET = MAC;
  MLME_RESET = MAC;
  MLME_BEACON_NOTIFY = MAC;
  MLME_SCAN = MAC;
  MCPS_DATA = MAC;
  MCPS_PURGE = MAC;
  MLME_ASSOCIATE = MAC;
  MLME_DISASSOCIATE = MAC;
  MLME_COMM_STATUS = MAC;
  MLME_RX_ENABLE = MAC;
  MLME_POLL = MAC;
  MLME_ORPHAN = MAC;
  IEEE154Frame = MAC;
  IEEE154BeaconFrame = MAC;
  IEEE154TxBeaconPayload = MAC;
  LocalExtendedAddress = MAC;
  PromiscuousMode = MAC;
  Packet = MAC;

  components CC2420TKN154C as PHY,
             new Alarm62500hz32C() as PHYAlarm1,
             new Alarm62500hz32VirtualizedC() as PHYAlarm2,
             new Alarm62500hz32C() as TKN154TimingPAlarm,
             LocalTime62500hzC, TKN154TimingP;

  // wire PHY to the PIB
  PHY.PIBUpdate[IEEE154_macShortAddress] -> MAC.PIBUpdate[IEEE154_macShortAddress];
  PHY.PIBUpdate[IEEE154_macPANId] -> MAC.PIBUpdate[IEEE154_macPANId];
  PHY.PIBUpdate[IEEE154_phyCurrentChannel] -> MAC.PIBUpdate[IEEE154_phyCurrentChannel];
  PHY.PIBUpdate[IEEE154_phyTransmitPower] -> MAC.PIBUpdate[IEEE154_phyTransmitPower];
  PHY.PIBUpdate[IEEE154_phyCCAMode] -> MAC.PIBUpdate[IEEE154_phyCCAMode];
  PHY.PIBUpdate[IEEE154_macPanCoordinator] -> MAC.PIBUpdate[IEEE154_macPanCoordinator];

  Timestamp = PHY;
  PHY.Alarm1 -> PHYAlarm1;
  PHY.Alarm2 -> PHYAlarm2;
  PHY.LocalTime -> LocalTime62500hzC;
  PHY.CaptureTime -> TKN154TimingP;
  PHY.ReliableWait -> TKN154TimingP;
  PHY.ReferenceTime -> TKN154TimingP;
  PHY.TimeCalc -> MAC;
  TKN154TimingP.TimeCalc -> MAC;
  TKN154TimingP.Leds -> LedsC;
  TKN154TimingP.CCA -> PHY;
  TKN154TimingP.SymbolAlarm -> TKN154TimingPAlarm;

  components new Timer62500C() as  MACTimer1,
             new Timer62500C() as  MACTimer2,
             new Timer62500C() as  MACTimer3,
             new Timer62500C() as  MACTimer4,
             new Timer62500C() as  MACTimer5;

  MAC.Timer1 -> MACTimer1;
  MAC.Timer2 -> MACTimer2;
  MAC.Timer3 -> MACTimer3;
  MAC.Timer4 -> MACTimer4;
  MAC.Timer5 -> MACTimer5;
  MAC.LocalTime -> LocalTime62500hzC;

  // wire MAC <-> PHY
  MAC.RadioTx -> PHY;
  MAC.UnslottedCsmaCa -> PHY;
  MAC.RadioRx -> PHY;
  MAC.RadioOff -> PHY;
  MAC.EnergyDetection -> PHY;
  MAC.PhySplitControl -> PHY;
  MAC.RadioPromiscuousMode -> PHY.RadioPromiscuousMode;
  PHY.FrameUtility -> MAC;

  components RandomC, LedsC, NoLedsC;
  MAC.Random -> RandomC;
  MAC.Leds -> LedsC;
  PHY.Random -> RandomC;

#ifdef TKN154_DEBUG
  components DebugC;
#endif
}
