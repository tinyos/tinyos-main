/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Initialize an M16c/62p TimerB to a particular mode. Expected to be
 * used at boot time.
 * @param mode The desired mode of the timer.
 * @param count_src Count source if applicable.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module M16c62pTimerBInitC(uint8_t mode,
                                  uint8_t count_src,
                                  uint16_t reload,
                                  bool enable_interrupt,
                                  bool start,
                                  bool allow_stop_mode)
{
  provides interface Init @atleastonce();
  uses interface HplM16c62pTimerBCtrl as TimerCtrl;
  uses interface HplM16c62pTimer as Timer;
}
implementation
{
  command error_t Init.init()
  {
    uint8_t tmp;
    error_t ret = SUCCESS;
    st_timer timer = {0};
    stb_counter counter = {0};

    atomic
    {
      call Timer.allowStopMode(allow_stop_mode);
      if (mode == TMR_TIMER_MODE)
      {
        timer.gate_func = M16C_TMR_TMR_GF_NO_GATE;
        timer.count_src = count_src;

        call TimerCtrl.setTimerMode(timer);
        call Timer.set(reload);
      }
      else if (mode == TMR_COUNTER_MODE)
      {
        // 'tmp' only used for avoiding "large integer
        // implicitly truncated to unsigned type" warning 
        tmp =  count_src & 1; 
        counter.event_source = tmp;

        call TimerCtrl.setCounterMode(counter);
        call Timer.set(reload);
      }
      else
      {
        ret = FAIL;
      }
      if (enable_interrupt)
      {
        call Timer.enableInterrupt();
      }
      if (start)
      {
        call Timer.on();
      }
    }
    return ret;
  }

  async event void Timer.fired() {}
}
