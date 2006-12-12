/* $Id: HalMAX136xAdvanced.nc,v 1.4 2006-12-12 18:23:06 vlahan Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "MAX136x.h"

interface HalMAX136xAdvanced {
  command error_t setScanMode(max136x_scanflag_t mode, uint8_t chanlow, uint8_t chanhigh);
  event void setScanModeDone(error_t error);
  command error_t setMonitorMode(uint8_t chanlow, uint8_t chanhigh, max136x_delayflag_t delay, uint8_t thresholds[12]); 
  event void setMonitorModeDone(error_t error);
  command error_t setConversionMode(bool bDifferential, bool bBipolar);
  event void setConversionModeDone(error_t error);  
  command error_t setClock(bool bExtClk);
  event void setClockDone(error_t error); 
  command error_t setRef(max136x_selflag_t sel, bool bInRefPwr);
  event void setRefDone(error_t error);
  command error_t getStatus();
  event void getStatusDone(error_t error, uint8_t status, 
                           max136x_data_t data);
  command error_t enableAlert(bool bEnable);
  event void enableAlertDone(error_t error);
  event void alertThreshold();

}
