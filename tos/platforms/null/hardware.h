
#ifndef HARDWARE_H
#define HARDWARE_H
inline void __nesc_enable_interrupt() { }
inline void __nesc_disable_interrupt() { }

typedef uint8_t __nesc_atomic_t;
typedef uint8_t mcu_power_t;

inline __nesc_atomic_t __nesc_atomic_start(void) @spontaneous() {
  return 0;
}

inline void __nesc_atomic_end(__nesc_atomic_t x) @spontaneous() { }
inline void __nesc_atomic_sleep() { }

/* Floating-point network-type support */
typedef float nx_float __attribute__((nx_base_be(afloat)));

inline float __nesc_ntoh_afloat(const void *COUNT(sizeof(float)) source) @safe() {
  float f;
  memcpy(&f, source, sizeof(float));
  return f;
}

inline float __nesc_hton_afloat(void *COUNT(sizeof(float)) target, float value) @safe() {
  memcpy(target, &value, sizeof(float));
  return value;
}

#endif
