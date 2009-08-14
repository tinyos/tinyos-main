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

generic configuration SecAMSenderC(am_id_t id)
{
  provides {
    interface AMSend;
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements as Acks;
    interface CC2420SecurityMode;
  }
}

implementation
{
  components ActiveMessageC;
  components NoLedsC;
  components LedsC;
  components new CC2420SpiC();
  components CC2420ActiveMessageC;
  components new AMSenderC(id);
  components new SecAMSenderP(id);

  AMSend = SecAMSenderP.AMSend;
  Packet = AMSenderC;
  Acks = CC2420ActiveMessageC;
  AMPacket = CC2420ActiveMessageC;
  CC2420SecurityMode = SecAMSenderP;

  SecAMSenderP.SubAMSend -> AMSenderC;
  SecAMSenderP.SecurityPacket -> AMSenderC;
  SecAMSenderP.Leds -> NoLedsC;
}
