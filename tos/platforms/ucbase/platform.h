// disable watchdog timer at startup (see AVR132: Using the Enhanced Watchdog Timer)
#include <avr/wdt.h> 
#define platform_bootstrap() { MCUSR = 0; wdt_disable(); }