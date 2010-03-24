/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */


/**
 *
 * @author Stephen Dawson-Haggerty
 */
 
configuration Ieee154MessageC  {
  provides {
    interface SplitControl;

    interface Resource as SendResource[uint8_t clientId];
    interface Ieee154Send;
    interface Receive as Ieee154Receive;

    interface Ieee154Packet;
    interface Packet;

    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface LowPowerListening;
    interface PacketLink;
  }

} implementation {
  components CC2420Ieee154MessageC as Msg;

  SplitControl = Msg;
  SendResource = Msg;
  Ieee154Send  = Msg;
  Ieee154Receive = Msg;
  Ieee154Packet = Msg;
  Packet = Msg;
  
  PacketAcknowledgements = Msg;
  LinkPacketMetadata = Msg;
  LowPowerListening = Msg;
  PacketLink = Msg;
}
