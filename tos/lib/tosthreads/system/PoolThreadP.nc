 
/**
 * @author Jeongyeup Paek (jpaek@enl.usc.edu)
 */
 
#include "thread.h"
#include "poolthread.h"

module PoolThreadP {
  provides {
    interface PoolThread;
  }
  uses {
#if (NUM_POOL_THREADS > 0)
    interface Thread as TinyThread0;
    interface ThreadInfo as ThreadInfo0;
#endif
#if (NUM_POOL_THREADS > 1)
    interface Thread as TinyThread1;
    interface ThreadInfo as ThreadInfo1;
#endif
#if (NUM_POOL_THREADS > 2)
    interface Thread as TinyThread2;
    interface ThreadInfo as ThreadInfo2;
#endif
#if (NUM_POOL_THREADS > 3)
    interface Thread as TinyThread3;
    interface ThreadInfo as ThreadInfo3;
#endif
#if (NUM_POOL_THREADS > 4)
    interface Thread as TinyThread4;
    interface ThreadInfo as ThreadInfo4;
#endif
#if (NUM_POOL_THREADS > 5)
    interface Thread as TinyThread5;
    interface ThreadInfo as ThreadInfo5;
#endif
#if (NUM_POOL_THREADS > 6)
    interface Thread as TinyThread6;
    interface ThreadInfo as ThreadInfo6;
#endif
#if (NUM_POOL_THREADS > 7)
    interface Thread as TinyThread7;
    interface ThreadInfo as ThreadInfo7;
#endif
#if (NUM_POOL_THREADS > 8)
    interface Thread as TinyThread8;
    interface ThreadInfo as ThreadInfo8;
#endif
#if (NUM_POOL_THREADS > 9)
    interface Thread as TinyThread9;
    interface ThreadInfo as ThreadInfo9;
#endif
    interface ThreadSleep;
    interface BitArrayUtils;
    interface ThreadScheduler;
  }
}
implementation {

    typedef struct pool_item {
        thread_t* info;
    } pool_item_t;

    pool_item_t m_list[NUM_POOL_THREADS];
    uint8_t thread_map[((NUM_POOL_THREADS - 1) / 8 + 1)];

    enum {
        THREAD_OVERFLOW = NUM_POOL_THREADS,
    };

    error_t start_thread(uint8_t id, void* arg) {
        if (id >= NUM_POOL_THREADS)
            return FAIL;
    #if (NUM_POOL_THREADS > 0)
        if (id == 0) return call TinyThread0.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 1)
        if (id == 1) return call TinyThread1.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 2)
        if (id == 2) return call TinyThread2.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 3)
        if (id == 3) return call TinyThread3.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 4)
        if (id == 4) return call TinyThread4.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 5)
        if (id == 5) return call TinyThread5.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 6)
        if (id == 6) return call TinyThread6.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 7)
        if (id == 7) return call TinyThread7.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 8)
        if (id == 8) return call TinyThread8.start(arg);
    #endif
    #if (NUM_POOL_THREADS > 9)
        if (id == 9) return call TinyThread9.start(arg);
    #endif
        return FAIL;
    }

    error_t stop_thread(uint8_t id) {
        if (id >= NUM_POOL_THREADS)
            return FAIL;
    #if (NUM_POOL_THREADS > 0)
        if (id == 0) return call TinyThread0.stop();
    #endif
    #if (NUM_POOL_THREADS > 1)
        if (id == 1) return call TinyThread1.stop();
    #endif
    #if (NUM_POOL_THREADS > 2)
        if (id == 2) return call TinyThread2.stop();
    #endif
    #if (NUM_POOL_THREADS > 3)
        if (id == 3) return call TinyThread3.stop();
    #endif
    #if (NUM_POOL_THREADS > 4)
        if (id == 4) return call TinyThread4.stop();
    #endif
    #if (NUM_POOL_THREADS > 5)
        if (id == 5) return call TinyThread5.stop();
    #endif
    #if (NUM_POOL_THREADS > 6)
        if (id == 6) return call TinyThread6.stop();
    #endif
    #if (NUM_POOL_THREADS > 7)
        if (id == 7) return call TinyThread7.stop();
    #endif
    #if (NUM_POOL_THREADS > 8)
        if (id == 8) return call TinyThread8.stop();
    #endif
    #if (NUM_POOL_THREADS > 9)
        if (id == 9) return call TinyThread9.stop();
    #endif
        return FAIL;
    }

    error_t pause_thread(uint8_t id) {
        if (id >= NUM_POOL_THREADS)
            return FAIL;
    #if (NUM_POOL_THREADS > 0)
        if (id == 0) return call TinyThread0.pause();
    #endif
    #if (NUM_POOL_THREADS > 1)
        if (id == 1) return call TinyThread1.pause();
    #endif
    #if (NUM_POOL_THREADS > 2)
        if (id == 2) return call TinyThread2.pause();
    #endif
    #if (NUM_POOL_THREADS > 3)
        if (id == 3) return call TinyThread3.pause();
    #endif
    #if (NUM_POOL_THREADS > 4)
        if (id == 4) return call TinyThread4.pause();
    #endif
    #if (NUM_POOL_THREADS > 5)
        if (id == 5) return call TinyThread5.pause();
    #endif
    #if (NUM_POOL_THREADS > 6)
        if (id == 6) return call TinyThread6.pause();
    #endif
    #if (NUM_POOL_THREADS > 7)
        if (id == 7) return call TinyThread7.pause();
    #endif
    #if (NUM_POOL_THREADS > 8)
        if (id == 8) return call TinyThread8.pause();
    #endif
    #if (NUM_POOL_THREADS > 9)
        if (id == 9) return call TinyThread9.pause();
    #endif
        return FAIL;
    }

    error_t resume_thread(uint8_t id) {
        if (id >= NUM_POOL_THREADS)
            return FAIL;
    #if (NUM_POOL_THREADS > 0)
        if (id == 0) return call TinyThread0.resume();
    #endif
    #if (NUM_POOL_THREADS > 1)
        if (id == 1) return call TinyThread1.resume();
    #endif
    #if (NUM_POOL_THREADS > 2)
        if (id == 2) return call TinyThread2.resume();
    #endif
    #if (NUM_POOL_THREADS > 3)
        if (id == 3) return call TinyThread3.resume();
    #endif
    #if (NUM_POOL_THREADS > 4)
        if (id == 4) return call TinyThread4.resume();
    #endif
    #if (NUM_POOL_THREADS > 5)
        if (id == 5) return call TinyThread5.resume();
    #endif
    #if (NUM_POOL_THREADS > 6)
        if (id == 6) return call TinyThread6.resume();
    #endif
    #if (NUM_POOL_THREADS > 7)
        if (id == 7) return call TinyThread7.resume();
    #endif
    #if (NUM_POOL_THREADS > 8)
        if (id == 8) return call TinyThread8.resume();
    #endif
    #if (NUM_POOL_THREADS > 9)
        if (id == 9) return call TinyThread9.resume();
    #endif
        return FAIL;
    }

    thread_t *thread_info(uint8_t id) {
        if (id >= NUM_POOL_THREADS)
            return NULL;
    #if (NUM_POOL_THREADS > 0)
        if (id == 0) return call ThreadInfo0.get();
    #endif
    #if (NUM_POOL_THREADS > 1)
        if (id == 1) return call ThreadInfo1.get();
    #endif
    #if (NUM_POOL_THREADS > 2)
        if (id == 2) return call ThreadInfo2.get();
    #endif
    #if (NUM_POOL_THREADS > 3)
        if (id == 3) return call ThreadInfo3.get();
    #endif
    #if (NUM_POOL_THREADS > 4)
        if (id == 4) return call ThreadInfo4.get();
    #endif
    #if (NUM_POOL_THREADS > 5)
        if (id == 5) return call ThreadInfo5.get();
    #endif
    #if (NUM_POOL_THREADS > 6)
        if (id == 6) return call ThreadInfo6.get();
    #endif
    #if (NUM_POOL_THREADS > 7)
        if (id == 7) return call ThreadInfo7.get();
    #endif
    #if (NUM_POOL_THREADS > 8)
        if (id == 8) return call ThreadInfo8.get();
    #endif
    #if (NUM_POOL_THREADS > 9)
        if (id == 9) return call ThreadInfo9.get();
    #endif
        return NULL;
    }

    uint8_t getNextPoolId() {
        uint8_t i;
        for (i = 0; i < NUM_POOL_THREADS; i++) {
            if(call BitArrayUtils.getBit(thread_map, i) == 0)
                break;
        }
        if (i >= NUM_POOL_THREADS)
            return THREAD_OVERFLOW;
        return i;
    }

    command error_t PoolThread.allocate(uint8_t* id, void (*start_routine)(void*), void* arg) {
        thread_t *t;
        atomic {
            *id = getNextPoolId();
            if (*id != THREAD_OVERFLOW) {
                call BitArrayUtils.setBit(thread_map, *id);
                t = thread_info(*id);
                m_list[*id].info = t;
                m_list[*id].info->start_ptr = start_routine;
                if (start_thread(*id, arg) == SUCCESS) {
                    return SUCCESS;
                } else {
                    call BitArrayUtils.clrBit(thread_map, *id);
                    m_list[*id].info = NULL;
                }
            }
        }
        return FAIL;
    }

    command error_t PoolThread.release(uint8_t id) {
        atomic {
            call BitArrayUtils.clrBit(thread_map, id);
            m_list[id].info = NULL;
            if (stop_thread(id) == SUCCESS)
                return SUCCESS;
        }
        return FAIL;
    }

    command error_t PoolThread.pause(uint8_t id) {
        if (call BitArrayUtils.getBit(thread_map, id) == 1) {
            return pause_thread(id);
        }
        return FAIL;
    }

    command error_t PoolThread.resume(uint8_t id) {
        if (call BitArrayUtils.getBit(thread_map, id) == 1) {
            return resume_thread(id);
        }
        return FAIL;  
    }

    uint8_t findPoolIdFromThreadId(uint8_t id) {
        int i;
        for (i = 0; i < NUM_POOL_THREADS; i++) {
            if (call BitArrayUtils.getBit(thread_map, i) == 1)
                if (m_list[i].info->id == id)
                    return i;
        }
        return THREAD_OVERFLOW;
    }

    command error_t PoolThread.sleep(uint32_t milli) {
        call ThreadSleep.sleep(milli);
    }

#if (NUM_POOL_THREADS > 0)
    event void TinyThread0.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 1)
    event void TinyThread1.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 2)
    event void TinyThread2.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 3)
    event void TinyThread3.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 4)
    event void TinyThread4.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 5)
    event void TinyThread5.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 6)
    event void TinyThread6.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 7)
    event void TinyThread7.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 8)
    event void TinyThread8.run(void *arg) {}
#endif
#if (NUM_POOL_THREADS > 9)
    event void TinyThread9.run(void *arg) {}
#endif
}

