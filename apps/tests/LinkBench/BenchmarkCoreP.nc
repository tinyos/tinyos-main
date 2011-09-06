/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

#define  _DEBUG_MODE_

#include "BenchmarkCore.h"
#include "Benchmarks.h"

#define SET_STATE(s) atomic { call Leds.set(s); state = s; }

#if defined(_DEBUG_MODE_)
  #define _ASSERT_(cond) if(!(cond || profile.debug)){ profile.debug = __LINE__; }
#else
  #define str(s) s
  #define _ASSERT_(cond) str()
#endif

module BenchmarkCoreP @safe() {

  provides {
    interface Init;
    interface StdControl as Test;
    interface BenchmarkCore;
  }

  uses {
    interface Receive as RxTest;
    interface AMSend  as TxTest;
  
    interface Timer<TMilli> as TestTimer;
    interface Timer<TMilli> as TriggerTimer[uint8_t id];
    
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements as Ack;
    
#ifdef LOW_POWER_LISTENING
    interface LowPowerListening;
#endif
    
#ifdef PACKET_LINK
    interface PacketLink;
#endif

#ifdef TRAFFIC_MONITOR
    interface TrafficMonitor;
#endif

    interface CodeProfile;    
    interface StdControl as CodeProfileControl;
       
    interface Leds;
    
    interface Random;
    interface Init as RandomInit;
  }

}

implementation {

  enum {
    // Mote states
    STATE_INVALID     = 0x0,
    STATE_IDLE        = 0x1,
    STATE_CONFIGURED  = 0x2,
    STATE_PRE_RUN     = 0x3,
    STATE_RUNNING     = 0x4,
    STATE_POST_RUN    = 0x5,
    STATE_FINISHED    = 0x6,
    
    // Sendlock states
    UNLOCKED          = 0,
    LOCKED            = 1,
    
  };
  
  
  uint8_t     state, sendlock;
  setup_t     config;
  message_t   pkt;

  edge_t*     problem;
  uint8_t     c_edge_cnt,c_maxmoteid;
  
  stat_t      stats[MAX_EDGE_COUNT];
  profile_t   profile;
  
  // pre-computed values for faster operation
  pending_t   tickMask_start[MAX_TIMER_COUNT];
  pending_t   tickMask_stop [MAX_TIMER_COUNT];
  pending_t   outgoing_edges;
  
  // Bitmask specifying edges with pending send requests
  pending_t pending;
  
  // Last edge index on which we have sent message
  uint8_t  eidx = 0xFF;
  
  task void sendPending();
  
  /** CLEAN THE STATE MACHINE VARIABLES **/
  void cleanstate() {
   
    SET_STATE( STATE_INVALID )
   
    // Disassociate the problem
    problem = (edge_t*)NULL;
    c_edge_cnt = c_maxmoteid = 0;
    outgoing_edges = 0;
    
    // Clear configuration values
    memset(&config,0,sizeof(setup_t));
    memset(stats,0,sizeof(stat_t)*MAX_EDGE_COUNT);
    memset(&profile,0,sizeof(profile_t));
    
    memset(tickMask_start,0,sizeof(pending_t)*MAX_TIMER_COUNT);
    memset(tickMask_stop,0,sizeof(pending_t)*MAX_TIMER_COUNT);
    
    pending = 0x0;
    eidx = 0xFF;
    sendlock = UNLOCKED;
  
    call Packet.clear(&pkt);
    call Ack.noAck(&pkt);
        
    SET_STATE( STATE_IDLE )
  }
  
  /** START THE NEEDED TRIGGERING TIMERS **/
  void startTimers() {
    uint8_t i;
    uint32_t now;
    
    for(i = 0; i< MAX_TIMER_COUNT; ++i) {
    	// If the current timer is unused, do not start it
    	if ( tickMask_start[i] == 0 && tickMask_stop[i] == 0 )
    		continue;
   		
      now = call TriggerTimer.getNow[0]();
      if ( config.timers[i].isoneshot )
        call TriggerTimer.startOneShotAt[i]( 
          now + config.timers[i].delay, config.timers[i].period_msec);
      else
        call TriggerTimer.startPeriodicAt[i](
          now + config.timers[i].delay, config.timers[i].period_msec);
    }
  }
  
  /** STOP THE TRIGGERING TIMERS **/
  void stopTimers() {
    uint8_t i;
    for(i = 0; i< MAX_TIMER_COUNT; ++i)
      call TriggerTimer.stop[i]();
  }
    
  /** INITIALIZE THE COMPONENT **/
  command error_t Init.init() {
    cleanstate();
    call RandomInit.init();
    return SUCCESS;
  }
  
  /** REQUEST BECHMARK RESULTS **/
  command stat_t* BenchmarkCore.getStat(uint16_t idx) { 
    _ASSERT_( idx < MAX_EDGE_COUNT )
    _ASSERT_( state == STATE_FINISHED )
    _ASSERT_(idx < c_edge_cnt )
    
    return stats + idx;
  }
  
  /** REQUEST PROFILE INFORMATION **/
  command profile_t* BenchmarkCore.getProfile() {
    return &profile;
  }
  
  /** REQUEST EDGE COUNT **/
  command uint8_t BenchmarkCore.getEdgeCount() {
    _ASSERT_( state >= STATE_CONFIGURED )
    return c_edge_cnt;
  }
  
  /** REQUEST MOTE COUNT **/
  command uint8_t BenchmarkCore.getMaxMoteId() {
    _ASSERT_( state >= STATE_CONFIGURED )
    return c_maxmoteid;
  }  
  
  /** RESETS THE CORE **/
  command void BenchmarkCore.reset() {
    call Test.stop();
    cleanstate();
    signal BenchmarkCore.resetDone();
  }
  
  /** START THE REAL BENCHMARK */
  void startBenchmark() {
  
    dbg("Benchmark","BenchmarkCore startBenchmark\n");
  
    // If this node sends initial message(s)
    if ( pending )
      post sendPending();

    // Start the trigger timers
    startTimers();
    
    // Start the test timer
    dbg("Benchmark","BenchmarkCore start TestTimer\n");
    call TestTimer.startOneShot(config.runtime_msec);
  }

  void postNewTrigger(pending_t sbitmask) {
    uint8_t i = 0;
    pending_t blogd;
    
    _ASSERT_( sbitmask > 0 )
    _ASSERT_( state == STATE_RUNNING || state == STATE_IDLE || state == STATE_POST_RUN )
    _ASSERT_( ((~outgoing_edges) & sbitmask) == 0 )
    
    atomic {
      // Check which edges need to be backlogged
      blogd = pending & sbitmask;
      pending |= sbitmask;
    }

    // Count backlog values
    for ( i = 0; blogd; ++i, blogd >>= 1) {
      if ( blogd & 0x1 )
        ++(stats[i].backlogCount);
    }
    
    // Count trigger values
    for ( i = 0; sbitmask; ++i, sbitmask >>= 1) {
      if ( sbitmask & 0x1 ) {
        ++(stats[i].triggerCount);
        if ( problem[i].nums.send_num == INFINITE )
          problem[i].policy.inf_loop_on = 1;
      }
    }
  }

  
  /** SETUP THE BENCHMARK **/
  command void BenchmarkCore.setup(setup_t conf) {
    uint8_t idx;
    
    dbg("Benchmark","BenchmarkCore.setup\n");
    
    _ASSERT_( state == STATE_IDLE || state == STATE_CONFIGURED )
    _ASSERT_( conf.runtime_msec > 0 );
       
    // Do nothing if already configured or running or data is available
    if ( state == STATE_CONFIGURED )
      return;
    
    // Save the configuration
    config = conf;
    
    // Setup the problem
    // WARNING: This is a very dirty hack by intent. Benchmarks are preceded by a
    // separator edge having sender = INVALID_SENDER and receiver = problem number.
    // That separator edge we are now looking for!
    idx = 0;
    while ( problemSet[idx].receiver != 0 &&  // do not run past the last edge (PROBLEMSET_END)
            ! ( problemSet[idx].sender == INVALID_SENDER && 
                problemSet[idx].receiver == config.problem_idx ) ) {
      ++idx;
    }
    // In case we haven't found any benchmark with the requested id, kill the mote.
    if ( problemSet[idx].receiver == 0 ) {
      SET_STATE( STATE_INVALID )
      return;
    } else { 
      problem = problemSet + idx + 1;
    }
    
    c_maxmoteid = 1;
    // Initialize the edges
    for( idx = 0; problem[idx].sender != INVALID_SENDER; ++idx )
    {
      edge_t* edge = problem + idx;
      // Clean values that are changed during operation
      edge->policy.inf_loop_on = 0;
      edge->nums.left_num = edge->nums.send_num;
      edge->nextmsgid = START_MSG_ID;
            
      // Count the maximal mote id
      if ( edge->sender > c_maxmoteid )
        c_maxmoteid = edge->sender;
      if ( edge->receiver > c_maxmoteid && edge->receiver != ALL )
        c_maxmoteid = edge->receiver;
            
      // If the sender is not this node, continue
      if( edge->sender != TOS_NODE_ID )
        continue;
  
      // Set this bit because it is an outgoing edge from this mote
      outgoing_edges |= 1<<idx;
            
      // Set the pending bits if this node needs to send at start
      if ( edge->policy.start_trigger == SEND_ON_INIT ) {
        postNewTrigger( 1<<idx );

      // Set the timer masks if this node needs to send at timer ticks        
      } else if ( edge->policy.start_trigger == SEND_ON_TIMER ) {
        tickMask_start[edge->timers.start] |= 1 << idx;
      }
      
      // Set the timer masks if this node needs to stop on timer ticks        
      if ( edge->policy.stop_trigger & STOP_ON_TIMER )
        tickMask_stop[edge->timers.stop] |= 1 << idx;
    }
    c_edge_cnt = idx;
    
    SET_STATE( STATE_CONFIGURED )
    signal BenchmarkCore.setupDone();
  }
  
  /** START THE CURRENTLY CONFIGURED BENCHMARK */
  command error_t Test.start() { 
    _ASSERT_( state == STATE_CONFIGURED )
    dbg("Benchmark","BenchmarkCore Test.start\n");
    // Start the code profiler
    call CodeProfileControl.start();
    
#ifdef TRAFFIC_MONITOR
    // save the current time.
    profile.rtx_time = call TrafficMonitor.getActiveTime();
    profile.rstart_count = call TrafficMonitor.getStartCount();
    profile.rx_bytes = call TrafficMonitor.getRxBytes();
    profile.tx_bytes = call TrafficMonitor.getTxBytes();
    profile.rx_msgs = call TrafficMonitor.getRxMessages();
#endif
    
    // setup the applied MAC protocol
#ifdef LOW_POWER_LISTENING    
    if ( config.flags & GLOBAL_USE_MAC_LPL )
      call LowPowerListening.setLocalWakeupInterval(config.mac_setup[LPL_WAKEUP_OFFSET]);
#endif

#ifdef PACKET_LINK
    if ( config.flags & GLOBAL_USE_MAC_PLINK ) {
      call PacketLink.setRetries(&pkt,config.mac_setup[PLINK_RETRIES_OFFSET]);
      call PacketLink.setRetryDelay(&pkt,config.mac_setup[PLINK_DELAY_OFFSET]);
    }
#endif
    
    // If a pre-benchmark delay is requested, make a delay
    if ( config.pre_run_msec > 0 ) {
      SET_STATE ( STATE_PRE_RUN )
      call TestTimer.startOneShot( call Random.rand32() % config.pre_run_msec );
    } else {
      SET_STATE( STATE_RUNNING )
      startBenchmark();         
    }
    return SUCCESS; 
  }
    
  /** STOP A TEST */
  command error_t Test.stop() {
    uint8_t i = 0;
    
    dbg("Benchmark","BenchmarkCore Test.stop\n");
    
    _ASSERT_( state == STATE_PRE_RUN || state == STATE_RUNNING || state == STATE_POST_RUN )
    
    call TestTimer.stop();
    SET_STATE( STATE_FINISHED );
    stopTimers();
    
    // cleanup the MAC
#ifdef LOW_POWER_LISTENING    
    if ( config.flags & GLOBAL_USE_MAC_LPL )
      call LowPowerListening.setLocalWakeupInterval(0);
#endif

#ifdef PACKET_LINK
    if ( config.flags & GLOBAL_USE_MAC_PLINK ) {
      call PacketLink.setRetries(&pkt,0);
      call PacketLink.setRetryDelay(&pkt,0);
    }
#endif

    // compute the remained statistic
    for ( i = 0; pending; ++i, pending >>= 1) {
      if ( pending & 0x1 )
        ++(stats[i].remainedCount);
    }
    
    // Stop the code profiler
    call CodeProfileControl.stop();
      
    // Compute the mote-statistics
    profile.min_atomic = call CodeProfile.getMinAtomicLength();
    profile.min_interrupt = call CodeProfile.getMinInterruptLength();
    profile.min_latency = call CodeProfile.getMinTaskLatency();
      
    profile.max_atomic = call CodeProfile.getMaxAtomicLength();
    profile.max_interrupt = call CodeProfile.getMaxInterruptLength();
    profile.max_latency = call CodeProfile.getMaxTaskLatency();

#ifdef TRAFFIC_MONITOR
    // save the curent time.
    profile.rtx_time = call TrafficMonitor.getActiveTime() - profile.rtx_time;
    profile.rstart_count = call TrafficMonitor.getStartCount() - profile.rstart_count;
    profile.rx_bytes = call TrafficMonitor.getRxBytes() - profile.rx_bytes;
    profile.tx_bytes = call TrafficMonitor.getTxBytes() - profile.tx_bytes;
    profile.rx_msgs = call TrafficMonitor.getRxMessages() - profile.rx_msgs;
#endif 
   
    signal BenchmarkCore.finished();
    return SUCCESS;
  }
    
  event void TestTimer.fired() {
    dbg("Benchmark","BenchmarkCore TestTimer.fired\n");
  
    switch(state) {
    
      case STATE_PRE_RUN:
        SET_STATE( STATE_RUNNING )
        startBenchmark();
        break;
        
      case STATE_RUNNING:
        // Stop the trigger timers
        stopTimers();
        // check if we need a post-run state
        if ( config.post_run_msec > 0 ) {
          SET_STATE( STATE_POST_RUN )
          call TestTimer.startOneShot(config.post_run_msec);
          break;
        } 
        // break; missing: fallback to STATE_POST_RUN !
 
      case STATE_POST_RUN:
        call Test.stop();
        break;
        
      default:
        _ASSERT_( 0 )
    }
  }
  
  event void TriggerTimer.fired[uint8_t id]() {
    
    // start on timer tick
    if ( tickMask_start[id] != 0 ) {
      postNewTrigger(tickMask_start[id]);
      post sendPending();
    }
    
    // stop on timer tick
    if ( tickMask_stop[id] != 0 ) {
      uint8_t i = 0;
      pending_t temp = tickMask_stop[id];
      for ( i = 0; temp; ++i, temp >>= 1) {
        if ( (temp & 0x1) && (problem[i].policy.stop_trigger & STOP_ON_TIMER) ) {
          // This works for INFINITE and also for non-INF edges
          problem[i].policy.inf_loop_on = 0;
          problem[i].nums.left_num = problem[i].nums.send_num;
        }
      }
    }
    
  }
  
  event message_t* RxTest.receive(message_t* bufPtr, void* payload, uint8_t len) {
    
    testmsg_t* msg = (testmsg_t*)payload;
    // helper variables
    stat_t* stat = stats + msg->edgeid;
    edge_t* edge = problem + msg->edgeid;     
    
    dbg("Benchmark","RxTest.receive\n");
    
    // In case the message is sent to this mote (also)
    if ( state == STATE_RUNNING || state == STATE_POST_RUN ){

      ++(stat->receiveCount);

      // If the message id is ok
      if ( msg->msgid == edge->nextmsgid ) {
        ++(stat->consecutiveCount);

      } else {
        ++(stat->wrongCount);
        
        // If we got a message with a lower id than consecutive -> duplicate
        if ( msg->msgid < edge->nextmsgid )
          ++(stat->duplicateCount);
        // If we got a message with a higher id than consecutive -> we have missed messages
        else {
          ++(stat->forwardCount);
          stat->missedCount += msg->msgid - edge->nextmsgid;
        }
      }

      // Set the next consecutive message id
      edge->nextmsgid = msg->msgid + 1;

      // Check whether we have to reply
      if ( edge->reply_on & outgoing_edges ) {
        // in case of "reply-to broadcast message" policy, the reply_on bitmask could
        // contain edges whose source is not this mote.
        // that is why, a filter is applied (outgoing_edges).
        postNewTrigger(edge->reply_on & outgoing_edges );
        post sendPending();
      }
    }
    return bufPtr;
  }
  
  event void TxTest.sendDone(message_t* bufPtr, error_t error) {
    
    testmsg_t* msg = (testmsg_t*)(call Packet.getPayload(bufPtr,sizeof(testmsg_t)));
    bool validSend = TRUE, wasACK = FALSE, sendMore = TRUE;
    
   
    
    // helper variables
    stat_t* stat = stats + msg->edgeid;
    edge_t* edge = problem + msg->edgeid;

 dbg("Benchmark","TxTest.sendDone\n");
    _ASSERT_( sendlock == LOCKED )
    _ASSERT_( state == STATE_RUNNING || state == STATE_POST_RUN || state == STATE_FINISHED )
     
    if ( state == STATE_RUNNING || state == STATE_POST_RUN ) {

      _ASSERT_( edge->sender == TOS_NODE_ID )
      _ASSERT_( pending & (1 << msg->edgeid) )
      ++(stat->sendDoneCount);

      if ( error == SUCCESS ) {
        ++(stat->sendDoneSuccessCount);

        // If ACK is not requested
        if ( edge->policy.need_ack == 0 && (config.flags & GLOBAL_USE_ACK) == 0 ) {
          ++(edge->nextmsgid);

        // If ACK is requested and received
        } else if ( call Ack.wasAcked(bufPtr) ) {
          ++(edge->nextmsgid);
          ++(stat->wasAckedCount);
          wasACK = TRUE;
            
        // Otherwise ACK requested but not received
        } else {
          ++(stat->notAckedCount);
          validSend = FALSE;
        }
        
      } else {
        ++(stat->sendDoneFailCount);
        validSend = FALSE;
      }

      // If message is NOT considered to be sent
      if ( ! validSend ) {
        ++(stat->resendCount);

      } else {

        // Decrement the number of messages that are left to send
        // and restore the original value if necessary
        // this works for INFINITE and also for non-INF edges
        if ( edge->nums.send_num != INFINITE && --(edge->nums.left_num) == 0 ) {
          // Restore the value
          edge->nums.left_num = edge->nums.send_num;
          sendMore = FALSE;
        } 
        
        // Check if we need to stop sending on ACK
        if ( wasACK && (edge->policy.stop_trigger & STOP_ON_ACK) ) {
            // This works for INFINITE and also for non-INF edges
            edge->policy.inf_loop_on = 0;
            edge->nums.left_num = edge->nums.send_num;
            sendMore = FALSE;
        }
 
        // If the infinite sending loop has been stopped
        if ( edge->nums.send_num == INFINITE && !edge->policy.inf_loop_on ) {
          sendMore = FALSE;
        }   
      }
          
      // Remove the pending bit if applicable     
      if ( !sendMore ) {
        atomic { pending &= ~ (1 << msg->edgeid ); }
      } else {
        ++(stat->triggerCount);
      }
            
      sendlock = UNLOCKED;
      if ( pending )
        post sendPending();
    }
  }


  task void sendPending() {
    
    pending_t   pidx;
    am_addr_t   address;
    uint8_t     oldlock;
    testmsg_t*  t_msg;
    
    // safe locking    
    atomic{
      oldlock = sendlock;
      sendlock = LOCKED;
    }
    
    
    
        
    // In case we have any chance to send    
    if ( oldlock == UNLOCKED && state == STATE_RUNNING && pending ) {


      dbg("Benchmark","sendPending-1\n");

      // find the next edge on which there exist any request
      do {
        pidx = 1 << (++eidx);
        if ( pidx == 0 ) {
          eidx  = 0x0;
          pidx  = 0x1;
        }
      } while ( !(pending & pidx) );
      
      _ASSERT_( problem[eidx].sender == TOS_NODE_ID )
        
      // Compose the new message
      call Packet.clear(&pkt);
      t_msg = (testmsg_t*)(call Packet.getPayload(&pkt,sizeof(testmsg_t)));
      t_msg->edgeid = eidx;
      t_msg->msgid = problem[eidx].nextmsgid;
      
      // Find out the required addressing mode
      address = ( config.flags & GLOBAL_USE_BCAST ) ? AM_BROADCAST_ADDR : problem[eidx].receiver;
     
      dbg("Benchmark","sendPending address %d\n",address);
     
      // MAC specific settings
#ifdef LOW_POWER_LISTENING      
      if ( config.flags & GLOBAL_USE_MAC_LPL )
        call LowPowerListening.setRemoteWakeupInterval(
          &pkt,config.mac_setup[LPL_WAKEUP_OFFSET]);
#endif
      
#ifdef PACKET_LINK
      if ( config.flags & GLOBAL_USE_MAC_PLINK ) {
        call PacketLink.setRetries(&pkt,config.mac_setup[PLINK_RETRIES_OFFSET]);
        call PacketLink.setRetryDelay(&pkt,config.mac_setup[PLINK_DELAY_OFFSET]);
      }
#endif
      
      dbg("Benchmark","sendPending-2\n");
      
      // Find out whether we need to use ACK
      if ( (config.flags & GLOBAL_USE_ACK) || problem[eidx].policy.need_ack ) {
        call Ack.requestAck(&pkt);
      } else {
        call Ack.noAck(&pkt);
      }
        
      dbg("Benchmark","sendPending-3\n");
      
      // Send out
      switch ( call TxTest.send( address, &pkt, sizeof(testmsg_t)) ) {
        case SUCCESS :
        dbg("Benchmark","sendPending-4\n");
          ++(stats[eidx].sendSuccessCount);
          break;
        case FAIL :
        dbg("Benchmark","sendPending-5\n");
          ++(stats[eidx].sendFailCount);
          ++(stats[eidx].resendCount);
          sendlock = UNLOCKED;
          post sendPending();
          break;
        default :
        dbg("Benchmark","sendPending-6\n");
          _ASSERT_( 0 )
          break;
      }
      ++(stats[eidx].sendCount);
    }
  }

}
