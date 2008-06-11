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
 * Description - PXA27X Quick Capture Interface.
 * 
 * @author Konrad Lorincz
 * @version 1.0, August 10, 2005
 */
/**                                         
 * Modified and ported to tinyos-2.x.
 * 
 * @author Brano Kusy
 * @version October 25, 2007
 */

interface HplPXA27XQuickCaptInt
{
	command error_t init(uint8_t color);
  command void enable();
	command error_t setImageSize(uint16_t sizeX, uint16_t sizeY, uint8_t colorType);
	command void initDMA(uint32_t num_bytes, void *buf);
  async command void disableQuick();
  async command void startDMA();

  // Events/Interrupts
  command void enableStartOfFrame();
	command void disableStartOfFrame(); /*new*/
  async event void startOfFrame(); 

  command void enableEndOfFrame();
  async event void endOfFrame(); 

  command void enableEndOfLine();
  async event void endOfLine(); 

  command void enableRecvDataAvailable();
  async event void recvDataAvailable(uint8_t channel); 

  command void enableFIFOOverrun();
  async event void fifoOverrun(uint8_t channel);
}
