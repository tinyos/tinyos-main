#include "config.h"
#include <stdio.h>

#if USE_LEDS
#define TOGGLE(_n) call Led##_n.toggle()
#else
#define TOGGLE(_n) do { ; } while(0)
#endif

#if USE_TIMER
#define DECL_INTERFACE(_n) interface Timer<TPrec> as Alarm##_n
#define DEFN_FIRED(_n) \
  event void Alarm##_n.fired () \
  { \
    TOGGLE(_n);                                   \
    call Alarm##_n.startOneShot(1UL << (_n + BASE_SHIFT)); \
  }
#define CALL_START(_n) call Alarm##_n.startOneShot(0)
#else
#define DECL_INTERFACE(_n) interface Alarm<TPrec, uint32_t> as Alarm##_n
#define DEFN_FIRED(_n) \
  async event void Alarm##_n.fired () \
  { \
    TOGGLE(_n);                                   \
    call Alarm##_n.start(1UL << (_n + BASE_SHIFT)); \
  }
#define CALL_START(_n) call Alarm##_n.start(0)
#endif

module TestP {
  uses {
    interface Boot;
#if USE_LEDS
    interface Led as Led0;
    interface Led as Led1;
    interface Led as Led2;
    interface Led as Led3;
    interface Led as Led4;
    interface Led as Led5;
    interface Led as Led6;
    interface Led as Led7;
#endif /* USE_LEDS */
    DECL_INTERFACE(0);
#if 1 < ALARM_COUNT
    DECL_INTERFACE(1);
#if 2 < ALARM_COUNT
    DECL_INTERFACE(2);
#if 3 < ALARM_COUNT
    DECL_INTERFACE(3);
#if 4 < ALARM_COUNT
    DECL_INTERFACE(4);
#if 5 < ALARM_COUNT
    DECL_INTERFACE(5);
#if 6 < ALARM_COUNT
    DECL_INTERFACE(6);
#if 7 < ALARM_COUNT
    DECL_INTERFACE(7);
#endif /* ALARM_COUNT 7 */
#endif /* ALARM_COUNT 6 */
#endif /* ALARM_COUNT 5 */
#endif /* ALARM_COUNT 4 */
#endif /* ALARM_COUNT 3 */
#endif /* ALARM_COUNT 2 */
#endif /* ALARM_COUNT 1 */
  }
} implementation {

  DEFN_FIRED(0)
#if 1 < ALARM_COUNT
  DEFN_FIRED(1)
#if 2 < ALARM_COUNT
  DEFN_FIRED(2)
#if 3 < ALARM_COUNT
  DEFN_FIRED(3)
#if 4 < ALARM_COUNT
  DEFN_FIRED(4)
#if 5 < ALARM_COUNT
  DEFN_FIRED(5)
#if 6 < ALARM_COUNT
  DEFN_FIRED(6)
#if 7 < ALARM_COUNT
  DEFN_FIRED(7)
#endif /* ALARM_COUNT 7 */
#endif /* ALARM_COUNT 6 */
#endif /* ALARM_COUNT 5 */
#endif /* ALARM_COUNT 4 */
#endif /* ALARM_COUNT 3 */
#endif /* ALARM_COUNT 2 */
#endif /* ALARM_COUNT 1 */

#if USE_LEDS
  default async command void Led0.toggle() { }
  default async command void Led1.toggle() { }
  default async command void Led2.toggle() { }
  default async command void Led3.toggle() { }
  default async command void Led4.toggle() { }
  default async command void Led5.toggle() { }
  default async command void Led6.toggle() { }
  default async command void Led7.toggle() { }
#endif
  
  event void Boot.booted () {
    printf("Starting with %u %s alarms\r\n",
           ALARM_COUNT,
#if USE_TIMER
           "timer"
#else /* USE_TIMER */
#if USE_MUX
           "multiplex"
#else /* USE_MUX */
           "standard "
#endif /* USE_MUX */
#endif /* USE_TIMER */
      );
    CALL_START(0);
#if 1 < ALARM_COUNT
    CALL_START(1);
#if 2 < ALARM_COUNT
    CALL_START(2);
#if 3 < ALARM_COUNT
    CALL_START(3);
#if 4 < ALARM_COUNT
    CALL_START(4);
#if 5 < ALARM_COUNT
    CALL_START(5);
#if 6 < ALARM_COUNT
    CALL_START(6);
#if 7 < ALARM_COUNT
    CALL_START(7);
#endif /* ALARM_COUNT 7 */
#endif /* ALARM_COUNT 6 */
#endif /* ALARM_COUNT 5 */
#endif /* ALARM_COUNT 4 */
#endif /* ALARM_COUNT 3 */
#endif /* ALARM_COUNT 2 */
#endif /* ALARM_COUNT 1 */

  }
}
