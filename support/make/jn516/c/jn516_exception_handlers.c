#include <AppHardwareApi.h>

volatile uint32 led_i;
//unsigned char TX_BUFFER[100];

uint32 u32EPCR, u32EEAR, u32Stack;
char c[10];

inline void SET_PIN(int pin) { vAHI_DioSetOutput(0, 1 << (pin)); }
inline void CLEAR_PIN(int pin) { vAHI_DioSetOutput(1 << (pin), 0); }
void LEDS_ON() { SET_PIN(2); SET_PIN(3); SET_PIN(17); }
void LEDS_OFF() { CLEAR_PIN(2); CLEAR_PIN(3); CLEAR_PIN(17); }

void WAIT(int delay) { for (led_i = 0; led_i < (delay); led_i++) {} }
void SHORT_OFF()  { LEDS_OFF(); WAIT( 800111); }
void SHORT_ON()   { LEDS_ON();  WAIT( 400111); }
void LONG_ON()    { LEDS_ON();  WAIT(1000111); }
void MEDIUM_OFF() { LEDS_OFF(); WAIT(3000111); }
void LONG_OFF()   { LEDS_OFF(); WAIT(6000111); }

#define STACK_REG                   1
#define PROGRAM_COUNTER             18
#define EFFECTIVE_ADDR              19

void LED_INIT() { vAHI_DioSetDirection(0, 1 << 2); vAHI_DioSetDirection(0, 1 << 3); vAHI_DioSetDirection(0, 1 << 16); vAHI_DioSetDirection(0, 1 << 17); CLEAR_PIN(16); CLEAR_PIN(17); }

void SOS() {
  SHORT_ON();
	SHORT_OFF();
  SHORT_ON();
	SHORT_OFF();
  SHORT_ON();
	SHORT_OFF();
	LONG_ON();
	SHORT_OFF();
	LONG_ON();
	SHORT_OFF();
	LONG_ON();
	SHORT_OFF();
  SHORT_ON();
	SHORT_OFF();
  SHORT_ON();
	SHORT_OFF();
  SHORT_ON();
	MEDIUM_OFF();
}
void BLINK(int num) { int ii; for (ii = 0; ii < num; ii++) { SHORT_OFF(); LONG_ON(); } }

void UART_INIT(unsigned char* TX_BUFFER) {
	bAHI_UartEnable(E_AHI_UART_0, TX_BUFFER, 100, NULL, 0);
	vAHI_UartSetBaudRate(E_AHI_UART_0, E_AHI_UART_RATE_115200);
}

PUBLIC void vDebug(char *pcMessage)
{
  while (*pcMessage)
	{
    while ((u8AHI_UartReadLineStatus(0) & 0x20) == 0);
		vAHI_UartWriteData(0, *pcMessage);
		pcMessage++;
	}
}

PUBLIC void vUTIL_NumToString(uint32 u32Data, char *pcString)
{
  int    i;
  uint8  u8Nybble;

  for (i = 28; i >= 0; i -= 4)
  {
    u8Nybble = (uint8)((u32Data >> i) & 0x0f);
    u8Nybble += 0x30;
    if (u8Nybble > 0x39)
      u8Nybble += 7;
    *pcString = u8Nybble;
    pcString++;
  }
  *pcString = 0;
}

void PRINT_ADDRESSES(uint32* pu32Stack) {
  u32EPCR = pu32Stack[PROGRAM_COUNTER];
  u32EEAR = pu32Stack[EFFECTIVE_ADDR];
  u32Stack = pu32Stack[STACK_REG];
  vUTIL_NumToString(u32EPCR, c);
  vDebug("PC: ");
  vDebug(c);
  vDebug("\n");
  vUTIL_NumToString(u32EEAR, c);
  vDebug("Eff. Addr.: ");
  vDebug(c);
  vDebug("\n");
  vUTIL_NumToString(u32Stack, c);
  vDebug("SP: ");
  vDebug(c);
  vDebug("\n");
}

void _jn516_custom_exception_bus_error(uint32* pu32Stack, int type) {
  unsigned char TX_BUFFER[100];
  LED_INIT();
  UART_INIT(TX_BUFFER);
  while (TRUE) {
  	SOS();
  	BLINK(1);
    vDebug("Bus Error\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}

void _jn516_custom_exception_unaligned_access(uint32* pu32Stack, int type) {
  unsigned char TX_BUFFER[100];
  LED_INIT();
  UART_INIT(TX_BUFFER);
  while (TRUE) {
  	SOS();
  	BLINK(2);
    vDebug("Unaligned Access\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}

void _jn516_custom_exception_illegal_instruction(uint32* pu32Stack, int type) {
  unsigned char TX_BUFFER[100];
  LED_INIT();
  UART_INIT(TX_BUFFER);
  while (TRUE) {
  	SOS();
  	BLINK(3);
    vDebug("Illegal Instruction\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}
/*
void _jn516_custom_exception_sys_call(uint32* pu32Stack, int type) {
  LED_INIT();
  UART_INIT();
  while (TRUE) {
  	SOS();
  	BLINK(4);
    vDebug("Sys Call\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}

void _jn516_custom_exception_trap(uint32* pu32Stack, int type) {
  LED_INIT();
  UART_INIT();
  while (TRUE) {
  	SOS();
  	BLINK(5);
    vDebug("Trap\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}

void _jn516_custom_exception_external_interrupt(uint32* pu32Stack, int type) {
  LED_INIT();
  UART_INIT();
  while (TRUE) {
  	SOS();
  	BLINK(6);
    vDebug("External Interrupt\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}
*/

void _jn516_custom_exception_stack_overflow(uint32* pu32Stack, int type) {
  unsigned char TX_BUFFER[100];
  LED_INIT();
  UART_INIT(TX_BUFFER);
  while (TRUE) {
  	SOS();
  	BLINK(7);
    vDebug("Stack Overflow\n");
  	PRINT_ADDRESSES(pu32Stack);
  	LONG_OFF();
  }
}
