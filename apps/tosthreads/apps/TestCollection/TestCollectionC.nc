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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

#include "MultihopOscilloscope.h"

module TestCollectionC {
  uses {
    interface Boot;
    interface Thread as MainThread;
    interface BlockingRead<uint16_t>;
    interface BlockingStdControl as RadioStdControl;
    interface Packet;
    interface BlockingSend;
    interface BlockingReceive;
    interface BlockingStdControl as RoutingControl;
    interface RootControl;
    interface Leds;
    interface BlockingStdControl as SerialStdControl;
    interface BlockingAMSend as SerialBlockingSend;
  }
}

implementation {
  static void fatal_problem();
  
  oscilloscope_t local;
  uint8_t reading = 0;   /* 0 to NREADINGS */
  message_t sendbuf;
  message_t recvbuf;
  
  void fatal_problem();
  void report_problem();
  void report_sent();
  void report_received();
  
  event void Boot.booted() {
    local.interval = DEFAULT_INTERVAL;
    local.id = TOS_NODE_ID;
    local.version = 0;
    
    call MainThread.start(NULL);
  }
  
  event void MainThread.run(void* arg) {
    while (call RadioStdControl.start() != SUCCESS);
    while (call RoutingControl.start() != SUCCESS);
    
    if (local.id % 500 == 0) {
      while (call SerialStdControl.start() != SUCCESS);
      call RootControl.setRoot();
      for (;;) {
        if (call BlockingReceive.receive(&recvbuf, 0) == SUCCESS) {
          oscilloscope_t *recv_o = (oscilloscope_t *) call BlockingReceive.getPayload(&recvbuf, sizeof(oscilloscope_t));
          oscilloscope_t *send_o = (oscilloscope_t *) call SerialBlockingSend.getPayload(&sendbuf, sizeof(oscilloscope_t));
          memcpy(send_o, recv_o, sizeof(oscilloscope_t));
          call SerialBlockingSend.send(AM_BROADCAST_ADDR, &sendbuf, sizeof(oscilloscope_t));
          report_received();
        }
      }
    } else {
      uint16_t var;
      
      for (;;) {
        if (reading == NREADINGS) {
          oscilloscope_t *o = (oscilloscope_t *) call BlockingSend.getPayload(&sendbuf, sizeof(oscilloscope_t));
          if (o == NULL) {
            fatal_problem();
            return;
          }
          memcpy(o, &local, sizeof(oscilloscope_t));
          if (call BlockingSend.send(&sendbuf, sizeof(oscilloscope_t)) == SUCCESS) {
            report_sent();
          } else {
            report_problem();
          }
        
          reading = 0;
        }
          
        if (call BlockingRead.read(&var) == SUCCESS) {
          local.readings[reading++] = var;
        }
        
        call MainThread.sleep(local.interval);
      }
    }
  }
  
  // Use LEDs to report various status issues.
  void fatal_problem() { 
    call Leds.led0On(); 
    call Leds.led1On();
    call Leds.led2On();
  }

  void report_problem() { call Leds.led0Toggle(); }
  void report_sent() { call Leds.led1Toggle(); }
  void report_received() { call Leds.led2Toggle(); }
}
