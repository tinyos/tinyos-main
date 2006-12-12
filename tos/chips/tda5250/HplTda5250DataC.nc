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
 * Controlling the TDA5250 at the HPL layer.
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
configuration HplTda5250DataC {
  provides {
    interface Init;
    interface HplTda5250Data;
		interface HplTda5250DataControl;
    interface ResourceRequested;
    interface Resource as Resource;
  }
}
implementation {

  components HplTda5250DataP,
      Tda5250RadioIOC,
			HplTda5250DataIOC;

  Init = HplTda5250DataP;
  Resource = HplTda5250DataP.Resource;
  ResourceRequested = HplTda5250DataP.ResourceRequested;
  HplTda5250Data = HplTda5250DataP;
  HplTda5250DataControl = HplTda5250DataP;

  HplTda5250DataP.DATA -> Tda5250RadioIOC.Tda5250RadioDATA;
	HplTda5250DataP.Uart -> HplTda5250DataIOC.UartStream;
  HplTda5250DataP.UartDataControl -> HplTda5250DataIOC.UartDataControl;
	HplTda5250DataP.UartResource -> HplTda5250DataIOC.Resource;
	HplTda5250DataP.UartResourceRequested -> HplTda5250DataIOC.ResourceRequested;

}
