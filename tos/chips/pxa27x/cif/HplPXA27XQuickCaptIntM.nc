/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * Wiring for the PXA27X Quick Capture Interface.
 * 
 * @author Konrad Lorincz
 * @version 1.0 - September 10, 2005
 */
 /**                                         
 * Modified and ported to tinyos-2.x.
 * 
 * @author Brano Kusy (branislav.kusy@gmail.com)
 * @version October 25, 2007
 */
#include "PXA27XQuickCaptInt.h"
#include "DMA.h"
#include "dmaArray.h"

module HplPXA27XQuickCaptIntM
{
    provides interface HplPXA27XQuickCaptInt;
    
    uses interface HplPXA27xInterrupt as PPID_CIF_Irq;
    uses interface Leds;
    uses interface GeneralIO as LED_PIN;
    uses interface dmaArray;
    uses interface HplPXA27xDMAChnl as pxa_dma;
}
implementation
{
    
  DescArray descArray;  
  void CIF_configurePins();
  
  void CIF_init(uint8_t color){ 
        CIF_configurePins();

        //atomic enabledInterrupts = 0;

        CKEN |= CKEN24_CIF;              // enable the CIF clock
    
        call PPID_CIF_Irq.allocate(); // generate an CIF interrupt
        call PPID_CIF_Irq.enable();   // enable the CIF interrupt mask
        
        // ------------------------------------------------------
        // (1) - Disable the CIF interface
        call HplPXA27XQuickCaptInt.disableQuick();
        
        // (2) - Set the timing/clocks
        // a. Have the mote supply the MCLK to the camera sensor
        CICR4 = CICR4_DIV(CICR4, 1);  // Set the MCLK clock rate to 15 MHz
        CICR4 |= CICR4_MCLK_EN;
		//was: CICR4 = CICR4_DIV(CICR4, 2);  // Set the MCLK clock rate to 15 MHz
        // b. Have the camera suply the PCLK to the mote
        CICR4 |= CICR4_PCLK_EN;

        // c. Set the synchronization signals to be active low
        //was: CICR4 |= CICR4_HSP;  // HREF is active-low? 
        //was: CICR4 |= CICR4_VSP;  // VSYNC is active-low
		// it seems we use active VSP and HSP 

        // (3) - Set the data format (nbr pixels, color space, encoding, etc.)
		//was: CICR1 = CICR1_DW(CICR1, 4);          // Data Width:  10 bits wide data from the sensor
        //was: CICR1 = CICR1_COLOR_SP(CICR1, 0);    // Color Space: Raw
        //was: CICR1 = CICR1_RAW_BPP(CICR1, 2);     // Raw bits per pixel: 10
        //was: CICR3 = CICR3_LPF(CICR3, (1024-1));  // lines per frame (rows): 1024
        //was: CICR1 = CICR1_PPL(CICR1, (1280-1));  // pixels per line (cols): 1280            
  		CICR1 = CICR1_DW(CICR1, 2);     // Data Width:  8 bits wide data from the sensor
  		CICR1 = CICR1_RGB_BPP(CICR1, 2);  // RGB bits per pixel: 16
  		CICR1 = CICR1_RAW_BPP(CICR1, 0);  // RAW bits per pixel: 8
  		CICR3 = CICR3_LPF(CICR3, (240-1));  // lines per frame (height): 240    
  		if (color == COLOR_RGB565)
  		{
  		  CICR1 = CICR1_PPL(CICR1, (320-1));  // pixels per line (width): 320
  		  CICR1 = CICR1_COLOR_SP(CICR1, 1); // Color Space: RGB
  		}
  		else
  		{
  		  CICR1 = CICR1_PPL(CICR1, (2*320-1));  // pixels per line (width): 320
  		  CICR1 = CICR1_COLOR_SP(CICR1, 0); // Color Space: RAW (default)
  		} 
        
        // (4) - FIFO DMA threshold level
        CIFR = CIFR_THL_0(CIFR, 0);          // 96 bytes of more in FIFO 0 causea a DMA request
                      
        // (5) - Initialize the DMA                                                 
        //CIF_InitDMA();
                                  
        // (6) - Enable the CIF with DMA
        //was: CIF_setAndEnableCICR0(CICR0 | CICR0_DMA_EN);
      
  		//new: all CICR0 bits should be set with a single command
  		CICR0 = ((CICR0 | CICR0_DMA_EN) & ~(CICR0_SOFM)) & ~(CICR0_EOFM); 
    }

    void CIF_setAndEnableCICR0(uint32_t data)
    {
        call HplPXA27XQuickCaptInt.disableQuick();
        CICR0 = (data | CICR0_EN);
    }
    
    command error_t HplPXA27XQuickCaptInt.init(uint8_t color) 
    {
        CIF_init(color); 
        return SUCCESS;
    }

    command void HplPXA27XQuickCaptInt.enable()
    {
        uint32_t tempCICR0 = CICR0;
        tempCICR0 |= CICR0_EN;
        tempCICR0 &= ~(CICR0_DIS); //new
        CICR0 = tempCICR0;
    } 

    async command void HplPXA27XQuickCaptInt.disableQuick()
    {
        CICR0 &= ~(CICR0_EN);
        CISR |= CISR_CQD;
    } 

    async command void HplPXA27XQuickCaptInt.startDMA()
    {
        atomic{
            uint32_t dcsr = call pxa_dma.getDCSR();

            call pxa_dma.setMap(DMAREQ_CIF_RECV_0);
          	call pxa_dma.setDALGNbit(1);
            dcsr &= ~(DCSR_RUN);
            dcsr &= ~(DCSR_NODESCFETCH);
            call pxa_dma.setDCSR(dcsr);
            call pxa_dma.setDDADR((uint32_t)call dmaArray.array_get(&descArray, 0) );
            call pxa_dma.setDCSR((call pxa_dma.getDCSR()) | DCSR_RUN );
        }
    }

    command error_t HplPXA27XQuickCaptInt.setImageSize(uint16_t sizeX, uint16_t sizeY, uint8_t colorType)
    {
        //was: if (sizeX > 2048 || sizeY > 2048)
    if (sizeX > 320 || sizeY > 240) 
            return FAIL;

    

    // (1) - Set the Quick Capture Interface Size
    //was: call HplPXA27XQuickCaptInt.disableQuick();
    CICR3 = CICR3_LPF(CICR3, (sizeY-1));
    //was: CICR1 = CICR1_PPL(CICR1, (sizeX-1));
    if (colorType == COLOR_RGB565) 
      CICR1 = CICR1_PPL(CICR1, (sizeX-1));
    else 
      CICR1 = CICR1_PPL(CICR1, (2*sizeX-1));
 
    //was: call HplPXA27XQuickCaptInt.enable();

    // (2) - Set the DMA transfer size
    //was: nbrBytesToTransfer = sizeX*sizeY*2;  // each pixel is 2 bytes

    return SUCCESS;
    }

    command void HplPXA27XQuickCaptInt.initDMA(uint32_t num_bytes, void *buf) //CIF_InitDMA() 
    {
			call dmaArray.init(&descArray, num_bytes, CIBR0_ADDR, buf);
    }

    command void HplPXA27XQuickCaptInt.disableStartOfFrame()      {CIF_setAndEnableCICR0(CICR0 | CICR0_SOFM);}
    command void HplPXA27XQuickCaptInt.enableStartOfFrame()       {CIF_setAndEnableCICR0(CICR0 & ~(CICR0_SOFM));}
    command void HplPXA27XQuickCaptInt.enableEndOfFrame()         {CIF_setAndEnableCICR0(CICR0 & ~(CICR0_EOFM));}
    command void HplPXA27XQuickCaptInt.enableEndOfLine()          {CIF_setAndEnableCICR0(CICR0 & ~(CICR0_EOLM));}
    command void HplPXA27XQuickCaptInt.enableRecvDataAvailable()  {CIF_setAndEnableCICR0(CICR0 & ~(CICR0_RDAVM));}
    command void HplPXA27XQuickCaptInt.enableFIFOOverrun()        {CIF_setAndEnableCICR0(CICR0 & ~(CICR0_FOM));}

  default async event void HplPXA27XQuickCaptInt.startOfFrame() { return;}
  default async event void HplPXA27XQuickCaptInt.endOfFrame() { return;}
  default async event void HplPXA27XQuickCaptInt.endOfLine() { return;}
  default async event void HplPXA27XQuickCaptInt.recvDataAvailable(uint8_t channel) { return;}
  default async event void HplPXA27XQuickCaptInt.fifoOverrun(uint8_t channel) { return;}

    async event void PPID_CIF_Irq.fired() 
    {            
      
        //atomic{printfUART(">>>>>>>>>>>>>>> PPID_CIF_Irq.fired() >>>>>>>>>>>\n", "");}
        volatile uint32_t tempCISR;

        atomic {  tempCISR = CISR; }
        // Start-Of-Frame
        if ((tempCISR & CISR_SOF) && (~(CICR0) & CICR0_SOFM)) {
            atomic CISR |= CISR_SOF;
            signal HplPXA27XQuickCaptInt.startOfFrame();
            // this disables CIF after the current frame capture is done 
            CICR0 |= CICR0_DIS;		
        }
        // End-Of-Frame
        if ((tempCISR & CISR_EOF) && (~(CICR0) & CICR0_EOFM)) {
            atomic CISR |= CISR_EOF;
            signal HplPXA27XQuickCaptInt.endOfFrame();
            return;           
        }
        // End-Of-Line
        if ((tempCISR & CISR_EOL) && (~(CICR0) & CICR0_EOLM)) {
            atomic CISR |= CISR_EOL;
            signal HplPXA27XQuickCaptInt.endOfLine();
        }
        // Receive-Data-Available
        if (~(CICR0) & CICR0_RDAVM) {
            if (tempCISR & CISR_RDAV_2) {  // channel 2
                atomic CISR |= CISR_RDAV_2;
                signal HplPXA27XQuickCaptInt.recvDataAvailable(2);        
            }
            if (tempCISR & CISR_RDAV_1) {  // channel 1
                atomic CISR |= CISR_RDAV_1;
                signal HplPXA27XQuickCaptInt.recvDataAvailable(1);        
            }
            if (tempCISR & CISR_RDAV_0) {  // channel 0
                atomic CISR |= CISR_RDAV_0;
                signal HplPXA27XQuickCaptInt.recvDataAvailable(0);
            }
        }  
        // FIFO Overrun
        if (~(CICR0) & CICR0_FOM) {
            if (tempCISR & CISR_IFO_2) {  // channel 2
                atomic CISR |= CISR_IFO_2;
                signal HplPXA27XQuickCaptInt.fifoOverrun(2);        
            }
            if (tempCISR & CISR_IFO_1) {  // channel 1
                atomic CISR |= CISR_IFO_1;
                signal HplPXA27XQuickCaptInt.fifoOverrun(1);        
            }
            if (tempCISR & CISR_IFO_0) {  // channel 0
                atomic CISR |= CISR_IFO_0;
                signal HplPXA27XQuickCaptInt.fifoOverrun(0);
            }
        }  

    }

    void CIF_configurePins()
    {
        // (1) - Configure the GPIO Alt functions and direction
        // --- Template ----
        //_GPIO_setaltfn(PIN, PIN_ALTFN);
        //_GPDR(PIN) &= ~_GPIO_bit(PIN);  // input
        //_GPDR(PIN) |= _GPIO_bit(PIN);   // output
        // -----------------
        

     	_GPIO_setaltfn(PIN_CIF_MCLK, PIN_CIF_MCLK_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_PCLK, PIN_CIF_PCLK_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_FV, PIN_CIF_FV_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_LV, PIN_CIF_LV_ALTFN);
    
    	_GPIO_setaltfn(PIN_CIF_DD0, PIN_CIF_DD0_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD1, PIN_CIF_DD1_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD2, PIN_CIF_DD2_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD3, PIN_CIF_DD3_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD4, PIN_CIF_DD4_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD5, PIN_CIF_DD5_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD6, PIN_CIF_DD6_ALTFN);
    	_GPIO_setaltfn(PIN_CIF_DD7, PIN_CIF_DD7_ALTFN);
    
    	GPDR(PIN_CIF_MCLK) |= _GPIO_bit(PIN_CIF_MCLK);   // output (if sensor is master)
    	GPDR(PIN_CIF_PCLK) &= ~_GPIO_bit(PIN_CIF_PCLK);  // input (if sensor is master)
    	GPDR(PIN_CIF_FV) &= ~_GPIO_bit(PIN_CIF_FV);  // input (if sensor is master)
    	GPDR(PIN_CIF_LV) &= ~_GPIO_bit(PIN_CIF_LV);  // input (if sensor is master)
    	GPDR(PIN_CIF_DD0) &= ~_GPIO_bit(PIN_CIF_DD0);  // input
    	GPDR(PIN_CIF_DD1) &= ~_GPIO_bit(PIN_CIF_DD1);  // input
    	GPDR(PIN_CIF_DD2) &= ~_GPIO_bit(PIN_CIF_DD2);  // input
    	GPDR(PIN_CIF_DD3) &= ~_GPIO_bit(PIN_CIF_DD3);  // input
    	GPDR(PIN_CIF_DD4) &= ~_GPIO_bit(PIN_CIF_DD4);  // input
    	GPDR(PIN_CIF_DD5) &= ~_GPIO_bit(PIN_CIF_DD5);  // input
    	GPDR(PIN_CIF_DD6) &= ~_GPIO_bit(PIN_CIF_DD6);  // input
    	GPDR(PIN_CIF_DD7) &= ~_GPIO_bit(PIN_CIF_DD7);  // input
    }
		
		async event void pxa_dma.interruptDMA(){
	    call pxa_dma.setDCMD(0);
	    call pxa_dma.setDCSR(DCSR_EORINT | DCSR_ENDINTR
						| DCSR_STARTINTR | DCSR_BUSERRINTR);
    }

}

