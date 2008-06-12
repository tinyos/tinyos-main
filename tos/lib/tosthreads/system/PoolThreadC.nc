 
/**
 * @author Jeongyeup Paek (jpaek@enl.usc.edu)
 */

#include "thread.h"
#include "poolthread.h"

configuration PoolThreadC {
  provides {
    interface PoolThread;
    interface ThreadNotification[uint8_t id];
  }
}
implementation {
  components MainC, PoolThreadP, ThreadP;
  PoolThread         = PoolThreadP;
  ThreadNotification = ThreadP.StaticThreadNotification;

  components BitArrayUtilsC;
  PoolThreadP.BitArrayUtils -> BitArrayUtilsC;
  components ThreadSleepC;
  PoolThreadP.ThreadSleep -> ThreadSleepC;
  components TinyThreadSchedulerC;
  PoolThreadP.ThreadScheduler -> TinyThreadSchedulerC;

#if (NUM_POOL_THREADS > 0)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread0;
  PoolThreadP.TinyThread0 -> TinyThread0;
  PoolThreadP.ThreadInfo0 -> TinyThread0;
#endif
#if (NUM_POOL_THREADS > 1)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread1;
  PoolThreadP.TinyThread1 -> TinyThread1;
  PoolThreadP.ThreadInfo1 -> TinyThread1;
#endif
#if (NUM_POOL_THREADS > 2)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread2;
  PoolThreadP.TinyThread2 -> TinyThread2;
  PoolThreadP.ThreadInfo2 -> TinyThread2;
#endif
#if (NUM_POOL_THREADS > 3)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread3;
  PoolThreadP.TinyThread3 -> TinyThread3;
  PoolThreadP.ThreadInfo3 -> TinyThread3;
#endif
#if (NUM_POOL_THREADS > 4)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread4;
  PoolThreadP.TinyThread4 -> TinyThread4;
  PoolThreadP.ThreadInfo4 -> TinyThread4;
#endif
#if (NUM_POOL_THREADS > 5)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread5;
  PoolThreadP.TinyThread5 -> TinyThread5;
  PoolThreadP.ThreadInfo5 -> TinyThread5;
#endif
#if (NUM_POOL_THREADS > 6)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread6;
  PoolThreadP.TinyThread6 -> TinyThread6;
  PoolThreadP.ThreadInfo6 -> TinyThread6;
#endif
#if (NUM_POOL_THREADS > 7)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread7;
  PoolThreadP.TinyThread7 -> TinyThread7;
  PoolThreadP.ThreadInfo7 -> TinyThread7;
#endif
#if (NUM_POOL_THREADS > 8)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread8;
  PoolThreadP.TinyThread8 -> TinyThread8;
  PoolThreadP.ThreadInfo8 -> TinyThread8;
#endif
#if (NUM_POOL_THREADS > 9)
  components new ThreadC(POOL_THREAD_STACK_SIZE) as TinyThread9;
  PoolThreadP.TinyThread9 -> TinyThread9;
  PoolThreadP.ThreadInfo9 -> TinyThread9;
#endif
}


