/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:T
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
 *
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 *
 */


configuration TestAppC{}
implementation {
	components MainC, TestC as App;
	App.Boot -> MainC;

    components new MuxAlarm32khz32C() as Alarm;
    App.Alarm -> Alarm;


    components Plain154FrameC;
    App.Frame -> Plain154FrameC;

    components Plain154MetadataC;
    App.Metadata -> Plain154MetadataC;

    components Plain154PacketC;
    App.PacketPayload -> Plain154PacketC;

    components SerialPrintfC;


    components TknTschC;
    App.Init -> TknTschC;
    App.TknTschInformationElement -> TknTschC;
    App.TknTschFrames -> TknTschC;
    App.PhyTx -> TknTschC;
    App.TknTschMlmeGet -> TknTschC.TknTschMlmeGet;
    App.TknTschMlmeSet -> TknTschC.TknTschMlmeSet;

    //components Plain154_Micro32C;
    App.PhyTx -> TknTschC; //Plain154_Micro32C.Plain154PhyTx;
    //App.PhyRx -> TknTschC; //Plain154_Micro32C.Plain154PhyRx;
    App.PLME_GET -> TknTschC; //Plain154_Micro32C.Plain154PlmeGet;
    App.PLME_SET -> TknTschC; //Plain154_Micro32C.Plain154PlmeSet;
    //App.Plain154PhyOff -> TknTschC; //Plain154_Micro32C.Plain154PhyOff;
    
    //App.Init -> Plain154_Micro32C;
}

