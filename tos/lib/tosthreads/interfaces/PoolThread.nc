 
/**
 * @author Jeongyeup Paek (jpaek@enl.usc.edu)
 **/

interface PoolThread {

  command error_t allocate(uint8_t* t, void (*start_routine)(void*), void* arg);

  command error_t release(uint8_t t);

  command error_t pause(uint8_t t);

  command error_t resume(uint8_t t);

  command error_t sleep(uint32_t milli);
}

