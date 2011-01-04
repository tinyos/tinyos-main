/*
* Copyright (c) 2010 Johns Hopkins University.
* All rights reserved.
*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Doug Carlson
 */

module TestSrpP {
  uses {
    interface Boot;
    interface Timer<TMilli>;
    interface SourceRouteSend;
    interface SourceRoutePacket;
    interface Receive;
    interface Random;
    interface SplitControl as RadioSplitControl;
  }
} 
implementation {
  message_t myMsg;
  uint8_t myCount = 0;
  #define SEND_INTERVAL 50
  #define SEND_COUNT 200

  typedef struct {
    uint8_t len;
    am_addr_t route[SRP_MAX_PATHLEN];
  } test_route_t;

  test_route_t routes[6] = {
    {0, {}},
    {3, {1,2,3}},
    {2, {2,3}},
    {0, {}},
    {3, {4,2,3}},
    {3, {5,2,3}},
  };
  

  typedef nx_struct {
    nx_uint8_t count;
  } test_payload_t;

  event void Boot.booted() {
    dbg("TestSrpP", "booted\n");
    call RadioSplitControl.start();
  }

  event void Timer.fired() {
    test_payload_t* payload;
    error_t err;

    myCount++;
    payload = ((test_payload_t*) call SourceRouteSend.getPayload(&myMsg, sizeof(test_payload_t)));
    payload -> count = myCount;

    //NOTE we don't want space allocated for the route outside of the header, so this is kind of awkward.
    //NOTE it seems bad that the sender needs to specify themselves, and also that the user needs to remember that a 1-hop path has 2 nodes in it.
    err = call SourceRouteSend.send(routes[TOS_NODE_ID].route, routes[TOS_NODE_ID].len , &myMsg, sizeof(test_payload_t));

    dbg("TestSrpP", "Sending %d : %d\n",myCount, err);
  }

  event void SourceRouteSend.sendDone(message_t* msg, error_t error) {
    //dbg("TestSrpP", "SendDone: %d\n", error);
    if (myCount < SEND_COUNT) {
      call Timer.startOneShot(call Random.rand16() % SEND_INTERVAL);
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    test_payload_t* tPayload;
    //dbg("TestSrpP", "Receive msg %p payload %p\n", msg, payload);
    tPayload = (test_payload_t*) payload;
    dbg("TestSrpP","Receive p->count %d from %d \n", tPayload->count, (call SourceRoutePacket.getRoute(msg))[0]);
    return msg;
  }

  event void RadioSplitControl.startDone(error_t error) {
    dbg("TestSrpP", "Radio startDone %d\n", error);

    if (routes[TOS_NODE_ID].len > 0 ) {
      call Timer.startOneShot(call Random.rand16() % SEND_INTERVAL);
    }
  }

  event void RadioSplitControl.stopDone(error_t error) {
  }
}
