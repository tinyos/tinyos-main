
#ifndef HARDWARE_H
#define HARDWARE_H
inline void __nesc_enable_interrupt() { }
inline void __nesc_disable_interrupt() { }

typedef uint8_t __nesc_atomic_t;

inline __nesc_atomic_t __nesc_atomic_start(void) @spontaneous() {
  return 0;
}

inline void __nesc_atomic_end(__nesc_atomic_t x) @spontaneous() { }
inline void __nesc_atomic_sleep() { }

#endif
