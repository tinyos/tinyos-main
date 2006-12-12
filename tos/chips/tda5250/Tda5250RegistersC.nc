/*
* Copyright (c) 2004, Technische Universitat Berlin
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
* - Neither the name of the Technische Universitat Berlin nor the names
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
* - Revision -------------------------------------------------------------
* $Revision: 1.4 $
* $Date: 2006-12-12 18:23:13 $
* ========================================================================
*/

/**
* Provides access to the registers of the tda5250 radio.
*
* @author Kevin Klues (klues@tkn.tu-berlin.de)
*/

configuration Tda5250RegistersC {
provides {
        interface Init;
        interface Resource;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_CONFIG>      as CONFIG;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_FSK>         as FSK;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_XTAL_TUNING> as XTAL_TUNING;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_LPF>         as LPF;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_ON_TIME>     as ON_TIME;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_OFF_TIME>    as OFF_TIME;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_COUNT_TH1>   as COUNT_TH1;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_COUNT_TH2>   as COUNT_TH2;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_RSSI_TH3>    as RSSI_TH3;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_RF_POWER>    as RF_POWER;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_CLK_DIV>     as CLK_DIV;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_XTAL_CONFIG> as XTAL_CONFIG;
        interface Tda5250WriteReg<TDA5250_REG_TYPE_BLOCK_PD>    as BLOCK_PD;
        interface Tda5250ReadReg<TDA5250_REG_TYPE_STATUS>       as STATUS;
        interface Tda5250ReadReg<TDA5250_REG_TYPE_ADC>          as ADC;
}
}
implementation {
        components Tda5250RegistersP
                        , Tda5250RadioIOC
                        , Tda5250RegCommC
        ;

        Init = Tda5250RegistersP;
        Init = Tda5250RegCommC;
        Resource = Tda5250RegCommC;

        CONFIG = Tda5250RegistersP.CONFIG;
        FSK = Tda5250RegistersP.FSK;
        XTAL_TUNING = Tda5250RegistersP.XTAL_TUNING;
        LPF = Tda5250RegistersP.LPF;
        ON_TIME = Tda5250RegistersP.ON_TIME;
        OFF_TIME = Tda5250RegistersP.OFF_TIME;
        COUNT_TH1 = Tda5250RegistersP.COUNT_TH1;
        COUNT_TH2 = Tda5250RegistersP.COUNT_TH2;
        RSSI_TH3 = Tda5250RegistersP.RSSI_TH3;
        RF_POWER = Tda5250RegistersP.RF_POWER;
        CLK_DIV = Tda5250RegistersP.CLK_DIV;
        XTAL_CONFIG = Tda5250RegistersP.XTAL_CONFIG;
        BLOCK_PD = Tda5250RegistersP.BLOCK_PD;
        STATUS = Tda5250RegistersP.STATUS;
        ADC = Tda5250RegistersP.ADC;

        Tda5250RegistersP.Pot -> Tda5250RegCommC;
        Tda5250RegistersP.Tda5250RegComm -> Tda5250RegCommC;

        Tda5250RegistersP.ENTDA -> Tda5250RadioIOC.Tda5250RadioENTDA;
}

