#ifndef _CONFIG_H_
#define _CONFIG_H_

#ifndef ALARM_COUNT
#define ALARM_COUNT (5)
#endif /* ALARM_COUNT */

#ifndef USE_MUX
#define USE_MUX 0
#endif /* USE_MUX */

#ifndef USE_TIMER
#define USE_TIMER 0
#endif /* USE_TIMER */

#ifndef USE_LEDS
#define USE_LEDS 1
#endif /* USE_LEDS */

#ifndef TPrec
#define TPrec TMilli
#endif /* TPrec */

#ifndef AlarmPrecC
#define AlarmPrecC AlarmMilli32C
#endif /* AlarmPrecC */

#ifndef MuxAlarmPrecC
#define MuxAlarmPrecC MuxAlarmMilli32C
#endif /* AlarmPrecC */

#ifndef TimerPrecC
#define TimerPrecC TimerMilliC
#endif /* TimerPrecC */

#ifndef BASE_SHIFT
#define BASE_SHIFT 7
#endif /* BASE_SHIFT */

#endif /* _CONFIG_H_ */

