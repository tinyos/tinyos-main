/*
 * Copyright (c) 2008 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */
 
module TinyThreadSchedulerP {
  provides {
    interface ThreadScheduler;
    interface Boot as TinyOSBoot;
    interface ThreadCleanup[uint8_t id];
  }
  uses {
    interface Boot as ThreadSchedulerBoot;
    interface ThreadInfo[uint8_t id];
    interface ThreadQueue;
    interface BitArrayUtils;
    interface McuSleep;
    interface Leds;
    interface Timer<TMilli> as PreemptionAlarm;
  }
}
implementation {
  //Pointer to currently running thread
  thread_t* current_thread;
  //Pointer to the tos thread
  thread_t* tos_thread;
  //Pointer to yielding thread
  thread_t* yielding_thread;
  //Number of threads started, and currently capable of running if given the chance
  uint8_t num_runnable_threads;
  //Thread queue for keeping track of threads waiting to run
  thread_queue_t ready_queue;
  
  void task alarmTask() {
    uint8_t temp;
    atomic temp = num_runnable_threads;
    if(temp <= 1)
      call PreemptionAlarm.stop();
    else if(temp > 1)
      call PreemptionAlarm.startOneShot(TOSTHREAD_PREEMPTION_PERIOD);
  }
  
  /* switch_threads()
   * This routine swaps the stack and allows a thread to run.
   * Needs to be in a separate function like this so that the 
   * PC counter gets saved on the stack correctly.
   *
   * This funciton should have NOTHING other than the call
   * to the SWITCH_CONTEXTS macro in it.  Otherwise we run
   * the risk of variables being pushed and popped by the 
   * compiler, causing obvious problems with the stack switching
   * thats going on....
   */
  void switchThreads() __attribute__((noinline)) {
    SWITCH_CONTEXTS(yielding_thread, current_thread);
  }
  void restoreThread() __attribute__((noinline)) {
    RESTORE_TCB(current_thread);
  }
  
  /* sleepWhileIdle() 
   * This routine is responsible for putting the mcu to sleep as 
   * long as there are no threads waiting to be run.  Once a
   * thread has been added to the ready queue the mcu will be
   * woken up and the thread will start running
   */
  void sleepWhileIdle() {
    while(TRUE) {
      bool mt;
      atomic mt = (call ThreadQueue.isEmpty(&ready_queue) == TRUE);
      if(!mt) break;
      call McuSleep.sleep();
    }
  }
  
  /* schedule_next_thread()
   * This routine does the job of deciding which thread should run next.
   * Should be complete as is.  Add functionality to getNextThreadId() 
   * if you need to change the actual scheduling policy.
   */
  void scheduleNextThread() {
    if(tos_thread->state == TOSTHREAD_STATE_READY)
      current_thread = call ThreadQueue.remove(&ready_queue, tos_thread);
    else
      current_thread = call ThreadQueue.dequeue(&ready_queue);

    current_thread->state = TOSTHREAD_STATE_ACTIVE;
  }
  
  /* interrupt()
   * This routine figures out what thread should run next
   * and then switches to it.
   */
  void interrupt(thread_t* thread) {
    yielding_thread = thread;
    scheduleNextThread();
    if(current_thread != yielding_thread) {
      switchThreads();
    }
  }
  
  /* suspend()
   * this routine is responsbile for suspending a thread.  It first 
   * checks to see if the mcu should be put to sleep based on the fact 
   * that the thread is being suspended.  If not, it proceeds to switch
   * contexts to the next thread on the ready queue.
   */
  void suspend(thread_t* thread) {
    //if there are no active threads, put the MCU to sleep
    //Then wakeup the TinyOS thread whenever the MCU wakes up again
    #ifdef TOSTHREADS_TIMER_OPTIMIZATION
      num_runnable_threads--;
	  post alarmTask();    
	#endif
    sleepWhileIdle();
    interrupt(thread);
  }
  
  void wakeupJoined(thread_t* t) {
    int i,j,k;
    k = 0;
    for(i=0; i<sizeof(t->joinedOnMe); i++) {
      for(j=0; j<8; j++) {
        if(t->joinedOnMe[i] & 0x1)
          call ThreadScheduler.wakeupThread(k);
        t->joinedOnMe[i] >>= 1;
        k++;
      }
    }
  }
  
  /* stop
   * This routine stops a thread by putting it into the inactive state
   * and decrementing any necessary variables used to keep track of
   * threads by the thread scheduler.
   */
  void stop(thread_t* t) {
    t->state = TOSTHREAD_STATE_INACTIVE;
    num_runnable_threads--;
    wakeupJoined(t);
    #ifdef TOSTHREADS_TIMER_OPTIMIZATION
	  post alarmTask();    
	#else
      if(num_runnable_threads == 1)
        call PreemptionAlarm.stop();
    #endif
    signal ThreadCleanup.cleanup[t->id]();
  }
  
  /* This executes and cleans up a thread
   */
  void threadWrapper() __attribute__((naked, noinline)) {
    thread_t* t;
    atomic t = current_thread;
    
    __nesc_enable_interrupt();
    (*(t->start_ptr))(t->start_arg_ptr);
    
    atomic {
      stop(t);
      sleepWhileIdle();
      scheduleNextThread();
      restoreThread();
    }
  } 
  
  event void ThreadSchedulerBoot.booted() {
    num_runnable_threads = 0;
    tos_thread = call ThreadInfo.get[TOSTHREAD_TOS_THREAD_ID]();
    tos_thread->id = TOSTHREAD_TOS_THREAD_ID;
    call ThreadQueue.init(&ready_queue);
    
    current_thread = tos_thread;
    current_thread->state = TOSTHREAD_STATE_ACTIVE;
    current_thread->init_block = NULL;
    signal TinyOSBoot.booted();
  }
  
  command error_t ThreadScheduler.initThread(uint8_t id) { 
    thread_t* t = (call ThreadInfo.get[id]());
    t->state = TOSTHREAD_STATE_INACTIVE;
    t->init_block = current_thread->init_block;
    call BitArrayUtils.clrArray(t->joinedOnMe, sizeof(t->joinedOnMe));
    PREPARE_THREAD(t, threadWrapper);
    return SUCCESS;
  }
  
  command error_t ThreadScheduler.startThread(uint8_t id) {
    atomic {
      thread_t* t = (call ThreadInfo.get[id]());
      if(t->state == TOSTHREAD_STATE_INACTIVE) {
        num_runnable_threads++;
        #ifdef TOSTHREADS_TIMER_OPTIMIZATION
          post alarmTask();
        #else 
          if(num_runnable_threads == 2)
            call PreemptionAlarm.startOneShot(TOSTHREAD_PREEMPTION_PERIOD);
        #endif
        t->state = TOSTHREAD_STATE_READY;
        call ThreadQueue.enqueue(&ready_queue, t);
        return SUCCESS;
      }
    }
    return FAIL;  
  }
  
  command error_t ThreadScheduler.stopThread(uint8_t id) { 
    atomic {
      thread_t* t = call ThreadInfo.get[id]();
      if((t->state == TOSTHREAD_STATE_READY) && (t->mutex_count == 0)) {
        call ThreadQueue.remove(&ready_queue, t);
        stop(t);
        return SUCCESS;
      }
      return FAIL;
    }
  }
  
  async command error_t ThreadScheduler.suspendCurrentThread() {
    atomic {
      if(current_thread->state == TOSTHREAD_STATE_ACTIVE) {
        current_thread->state = TOSTHREAD_STATE_SUSPENDED;
        suspend(current_thread);
        return SUCCESS;
      }
      return FAIL;
    }
  }
  
  async command error_t ThreadScheduler.interruptCurrentThread() { 
    atomic {
      if(current_thread->state == TOSTHREAD_STATE_ACTIVE) {
        current_thread->state = TOSTHREAD_STATE_READY;
        call ThreadQueue.enqueue(&ready_queue, current_thread);
        interrupt(current_thread);
        return SUCCESS;
      }
      return FAIL;
    }
  }
  
  async command error_t ThreadScheduler.joinThread(thread_id_t id) { 
    thread_t* t = call ThreadInfo.get[id]();
    atomic {
      if(current_thread == tos_thread)
        return FAIL;
      if (t->state != TOSTHREAD_STATE_INACTIVE) {
        call BitArrayUtils.setBit(t->joinedOnMe, current_thread->id);
        call ThreadScheduler.suspendCurrentThread();
        return SUCCESS;
      }
    }
    return EALREADY;
  }
  
  async command error_t ThreadScheduler.wakeupThread(uint8_t id) {
    thread_t* t = call ThreadInfo.get[id]();
    if((t->state) == TOSTHREAD_STATE_SUSPENDED) {
      t->state = TOSTHREAD_STATE_READY;
      call ThreadQueue.enqueue(&ready_queue, call ThreadInfo.get[id]());
      #ifdef TOSTHREADS_TIMER_OPTIMIZATION
        atomic num_runnable_threads++;
        post alarmTask();
      #endif
      return SUCCESS;
    }
    return FAIL;
  }
  
  async command uint8_t ThreadScheduler.currentThreadId() {
    atomic return current_thread->id;
  }    
  
  async command thread_t* ThreadScheduler.threadInfo(uint8_t id) {
    atomic return call ThreadInfo.get[id]();
  }   
  
  async command thread_t* ThreadScheduler.currentThreadInfo() {
    atomic return current_thread;
  }
  
  event void PreemptionAlarm.fired() {
    call PreemptionAlarm.startOneShot(TOSTHREAD_PREEMPTION_PERIOD);
    atomic {
      if((call ThreadQueue.isEmpty(&ready_queue) == FALSE)) {
        call ThreadScheduler.interruptCurrentThread();
      }
    }
  }
  
  default async command thread_t* ThreadInfo.get[uint8_t id]() {
    return NULL;
  }
}
