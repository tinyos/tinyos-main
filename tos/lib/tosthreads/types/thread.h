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

#ifndef THREAD_H
#define THREAD_H

#include "chip_thread.h"
#include "refcounter.h"

typedef uint8_t thread_id_t;                           //Typedef for thread_id_t
typedef uint8_t syscall_id_t;                          //Typedef for syscall_id_t
typedef thread_id_t tosthread_t;                       //Typedef for tosthread_t used to initialize a c-based thread

#ifndef TOSTHREAD_MAIN_STACK_SIZE
#define TOSTHREAD_MAIN_STACK_SIZE   500  //Default stack size for the main thread that spawns all other threads in the c based api
#endif

//Since thread initialization is encapsulated 
//inside a generic component, we can statically 
//know the number of threads created at compile 
//time
#define UQ_TOS_THREAD "Unique.TOS.Thread"
enum {
#ifdef MAX_NUM_THREADS
  TOSTHREAD_MAX_NUM_THREADS = MAX_NUM_THREADS,
#else
  TOSTHREAD_MAX_NUM_THREADS = 33,   //Maximum number of threads allowed to run (must be less than sizeof(thread_id_t))
#endif
  TOSTHREAD_NUM_STATIC_THREADS = uniqueCount(UQ_TOS_THREAD),  //The number of statically allocated threads
  TOSTHREAD_MAX_DYNAMIC_THREADS = TOSTHREAD_MAX_NUM_THREADS - TOSTHREAD_NUM_STATIC_THREADS,
  TOSTHREAD_TOS_THREAD_ID = TOSTHREAD_MAX_NUM_THREADS,        //The ID of the TinyOS thread (One more than max allowable threads)
  TOSTHREAD_INVALID_THREAD_ID = TOSTHREAD_MAX_NUM_THREADS,    //An invalid thread id
  TOSTHREAD_PREEMPTION_PERIOD = 5,                            //The preemption period for switching between threads
};

enum {
  INVALID_ID = 0xFF,            //ID reserved to indicate an invalid client connected
  SYSCALL_WAIT_ON_EVENT = 0,    //Indicates there is no actual system call to make, but rather should jsut wait on an event
};

typedef struct syscall syscall_t;
typedef struct thread thread_t;
typedef struct init_block init_block_t;

//This is the data structure associated with an initialization block from which 
//threads are spawned when dynamically loading them
struct init_block {
  void* globals;
  void (*init_ptr)(void*);
  void* init_arg;
  refcounter_t thread_counter;
};

//This is a system call data structure
struct syscall {
  //***** next_call must be at first position in struct for casting purposes *******
  struct syscall* next_call;        //Pointer to next system call for use in syscall queues when blocking on them
  syscall_id_t id;                  //client id of this system call for the particular syscall_queue within which it is being held
  thread_t* thread;                 //Pointer back to the thread with which this system call is associated
  void (*syscall_ptr)(struct syscall*);   //Pointer to the the function that actually performs the system call
  void* params;                     //Pointer to a set of parameters passed to the system call once it is running in task context
};

//This is a thread data structure
//This structure is 43 bytes long...
struct thread {
  //***** next_thread must be at first position in struct for casting purposes *******
  volatile struct thread* next_thread;  //Pointer to next thread for use in queues when blocked
  thread_id_t id;                       //id of this thread for use by the thread scheduler
  init_block_t* init_block;             //Pointer to an initialization block from which this thread was spawned
  stack_ptr_t stack_ptr;                //Pointer to this threads stack
  volatile uint8_t state;               //Current state the thread is in
  volatile uint8_t mutex_count;         //A reference count of the number of mutexes held by this thread
  void (*start_ptr)(void*);             //Pointer to the start function of this thread
  void* start_arg_ptr;                  //Pointer to the argument passed as a parameter to the start function of this thread
  syscall_t* syscall;                   //Pointer to an instance of a system call
  thread_regs_t regs;                   //Contents of the GPRs stored when doing a context switch
};

enum {
  TOSTHREAD_STATE_INACTIVE    = 0,  //This thread is inactive and cannot be run until started
  TOSTHREAD_STATE_ACTIVE      = 1,  //This thread is currently running and using the cpu
  TOSTHREAD_STATE_READY       = 2,  //This thread is not currently running, but is not blocked and has work to do 
  TOSTHREAD_STATE_SUSPENDED   = 3,  //This thread has been suspended by a system call (i.e. blocked)
};

#endif //THREAD_H
