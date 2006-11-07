/* $Id: HalLIS3L02DQAdvanced.nc,v 1.3 2006-11-07 19:30:54 scipio Exp $ */
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
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */
#include "LIS3L02DQ.h"

interface HalLIS3L02DQAdvanced {
  command error_t setDecimation(uint8_t factor);
  event void setDecimationDone(error_t error);
  command error_t enableAxis(bool bX, bool bY, bool bZ);
  event void enableAxisDone(error_t error);
  command error_t enableAlert(lis_alertflags_t xFlags, 
                      lis_alertflags_t yFlags, 
                      lis_alertflags_t zFlags, 
                      bool requireAll);
  event void enableAlertDone(error_t error);
  command error_t getAlertSource();
  event void getAlertSourceDone(error_t error, uint8_t vector);
  command error_t setTLow(uint8_t val);
  event void setTLowDone(error_t error);
  command error_t setTHigh(uint8_t val);
  event void setTHighDone(error_t error);

  event void alertThreshold();
}
