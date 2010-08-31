#include <avr/wdt.h>
#define platform_bootstrap() { MCUSR=0; wdt_disable(); }
