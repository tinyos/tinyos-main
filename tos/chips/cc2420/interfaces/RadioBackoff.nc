/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/**
 * Interface to request and specify backoff periods for messages
 * 
 * We use a call back method for setting the backoff as opposed to 
 * events that return backoff values.  
 * 
 * This is because of fan-out issues with multiple components wanting to
 * affect backoffs for whatever they're interested in:
 * If you signal out an *event* to request an initial backoff and
 * several components happen to be listening, then those components
 * would be required to return a backoff value.  We don't want that
 * behavior.
 
 * With this strategy, components can listen for the requests and then
 * decide if they want to affect the behavior.  If the component wants to
 * affect the behavior, it calls back using the setXYZBackoff(..) command.
 * If several components call back, then the last component to get its 
 * word in has the final say. 
 *
 * @author David Moss
 */
 
interface RadioBackoff {

  /**
   * Must be called within a requestInitialBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void setInitialBackoff(uint16_t backoffTime);
  
  /**
   * Must be called within a requestCongestionBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void setCongestionBackoff(uint16_t backoffTime);
  
  /**
   * Enable CCA for the outbound packet.  Must be called within a requestCca
   * event
   * @param ccaOn TRUE to enable CCA, which is the default.
   */
  async command void setCca(bool ccaOn);


  /**  
   * Request for input on the initial backoff
   * Reply using setInitialBackoff(..)
   * @param msg pointer to the message being sent
   */
  async event void requestInitialBackoff(message_t * ONE msg);
  
  /**
   * Request for input on the congestion backoff
   * Reply using setCongestionBackoff(..)
   * @param msg pointer to the message being sent
   */
  async event void requestCongestionBackoff(message_t * ONE msg);
  
  /**
   * Request for input on whether or not to use CCA on the outbound packet.
   * Replies should come in the form of setCca(..)
   * @param msg pointer to the message being sent
   */
  async event void requestCca(message_t * ONE msg);
}

