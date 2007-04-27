#ifndef ATM128_SIM_H_INCLUDED
#define ATM128_SIM_H_INCLUDED

/*
 * In normal avr code, the address and identifier of a register can be
 * the same. In a parallel simulation, this runs into issues with C typing,
 * as there are actually many copies of a register. So in TOSSIM the standard
 * name (e.g., PINE) refers to the actual memory location of the register while
 * ATM128_ (e.g., ATM128_PINE) refers to the register identifier.
 *
 */

//uint8_t atm128RegFile[100][0xa0];

#define _BV(bit) (1 << (bit))
//#define __SFR_OFFSET 0x20

#define _MMIO_BYTE(mem_addr) (*((volatile uint8_t *)(&atm128RegFile[sim_node()][mem_addr])))
#define _MMIO_WORD(mem_addr) (*((volatile uint16_t *)(&atm128RegFile[sim_node()][mem_addr])))
#define _SFR_MEM8(mem_addr) _MMIO_BYTE(mem_addr)
#define _SFR_MEM16(mem_addr) _MMIO_WORD(mem_addr)
#define _SFR_IO8(io_addr) _MMIO_BYTE((io_addr) )
#define _SFR_IO16(io_addr) _MMIO_WORD((io_addr) )

enum {
/* Input Pins, Port F */
  ATM128_PINF    = 0x00,

/* Input Pins, Port E */
  ATM128_PINE    = 0x01,

/* Data Direction Register, Port E */
  ATM128_DDRE    = 0x02,

/* Data Register, Port E */
  ATM128_PORTE   = 0x03,

/* ADC Data Register */
  ATM128_ADCW    = 0x04, /* for backwards compatibility */
#ifndef __ASSEMBLER__
  ATM128_ADC     = 0x04,
#endif
  ATM128_ADCL    = 0x04,
  ATM128_ADCH    = 0x05,

/* ADC Control and status register */
  ATM128_ADCSR   = 0x06,
  ATM128_ADCSRA  = 0x06, /* new name in datasheet (2467E-AVR-05/02) */

/* ADC Multiplexer select */
  ATM128_ADMUX   = 0x07,

/* Analog Comparator Control and Status Register */
  ATM128_ACSR    = 0x08,

/* USART0 Baud Rate Register Low */
  ATM128_UBRR0L  = 0x09,

/* USART0 Control and Status Register B */
  ATM128_UCSR0B  = 0x0A,

/* USART0 Control and Status Register A */
  ATM128_UCSR0A  = 0x0B,

/* USART0 I/O Data Register */
  ATM128_UDR0    = 0x0C,

/* SPI Control Register */
  ATM128_SPCR    = 0x0D,

/* SPI Status Register */
  ATM128_SPSR    = 0x0E,

/* SPI I/O Data Register */
  ATM128_SPDR    = 0x0F,

/* Input Pins, Port D */
  ATM128_PIND    = 0x10,

/* Data Direction Register, Port D */
  ATM128_DDRD    = 0x11,

/* Data Register, Port D */
  ATM128_PORTD   = 0x12,

/* Input Pins, Port C */
  ATM128_PINC    = 0x13,

/* Data Direction Register, Port C */
  ATM128_DDRC    = 0x14,

/* Data Register, Port C */
  ATM128_PORTC   = 0x15,

/* Input Pins, Port B */
  ATM128_PINB    = 0x16,

/* Data Direction Register, Port B */
  ATM128_DDRB    = 0x17,

/* Data Register, Port B */
  ATM128_PORTB   = 0x18,

/* Input Pins, Port A */
  ATM128_PINA    = 0x19,

/* Data Direction Register, Port A */
  ATM128_DDRA    = 0x1A,

/* Data Register, Port A */
  ATM128_PORTA   = 0x1B,

/* 0x1C..0x1F EEPROM */

/* Special Function I/O Register */
  ATM128_SFIOR   = 0x20,

/* Watchdog Timer Control Register */
  ATM128_WDTCR   = 0x21,

/* On-chip Debug Register */
  ATM128_OCDR    = 0x22,

/* Timer2 Output Compare Register */
  ATM128_OCR2    = 0x23,

/* Timer/Counter 2 */
  ATM128_TCNT2   = 0x24,

/* Timer/Counter 2 Control register */
  ATM128_TCCR2   = 0x25,

/* T/C 1 Input Capture Register */
  ATM128_ICR1    = 0x26,
  ATM128_ICR1L   = 0x26,
  ATM128_ICR1H   = 0x27,

/* Timer/Counter1 Output Compare Register B */
  ATM128_OCR1B   = 0x28,
  ATM128_OCR1BL  = 0x28,
  ATM128_OCR1BH  = 0x29,

/* Timer/Counter1 Output Compare Register A */
  ATM128_OCR1A   = 0x2A,
  ATM128_OCR1AL  = 0x2A,
  ATM128_OCR1AH  = 0x2B,

/* Timer/Counter 1 */
  ATM128_TCNT1   = 0x2C,
  ATM128_TCNT1L  = 0x2C,
  ATM128_TCNT1H  = 0x2D,

/* Timer/Counter 1 Control and Status Register */
  ATM128_TCCR1B  = 0x2E,

/* Timer/Counter 1 Control Register */
  ATM128_TCCR1A  = 0x2F,

/* Timer/Counter 0 Asynchronous Control & Status Register */
  ATM128_ASSR    = 0x30,

/* Output Compare Register 0 */
  ATM128_OCR0    = 0x31,

/* Timer/Counter 0 */
  ATM128_TCNT0   = 0x32,

/* Timer/Counter 0 Control Register */
  ATM128_TCCR0   = 0x33,

/* MCU Status Register */
  ATM128_MCUSR   = 0x34,
  ATM128_MCUCSR  = 0x34, /* new name in datasheet (2467E-AVR-05/02) */

/* MCU general Control Register */
  ATM128_MCUCR   = 0x35,

/* Timer/Counter Interrupt Flag Register */
  ATM128_TIFR    = 0x36,

/* Timer/Counter Interrupt MaSK register */
  ATM128_TIMSK   = 0x37,

/* External Interrupt Flag Register */
  ATM128_EIFR    = 0x38,

/* External Interrupt MaSK register */
  ATM128_EIMSK   = 0x39,

/* External Interrupt Control Register B */
  ATM128_EICRB   = 0x3A,

/* RAM Page Z select register */
  ATM128_RAMPZ   = 0x3B,

/* XDIV Divide control register */
  ATM128_XDIV    = 0x3C,

/* 0x3D..0x3E SP */

/* 0x3F SREG */
  ATM128_SREG    = 0x3F,

/* Extended I/O registers */

/* Data Direction Register, Port F */
  ATM128_DDRF    = 0x61,

/* Data Register, Port F */
  ATM128_PORTF   = 0x62,

/* Input Pins, Port G */
  ATM128_PING    = 0x63,

/* Data Direction Register, Port G */
  ATM128_DDRG    = 0x64,

/* Data Register, Port G */
  ATM128_PORTG   = 0x65,

/* Store Program Memory Control and Status Register */
  ATM128_SPMCR   = 0x68,
  ATM128_SPMCSR  = 0x68, /* new name in datasheet (2467E-AVR-05/02) */

/* External Interrupt Control Register A */
  ATM128_EICRA   = 0x6A,

/* External Memory Control Register B */
  ATM128_XMCRB   = 0x6C,

/* External Memory Control Register A */
  ATM128_XMCRA   = 0x6D,

/* Oscillator Calibration Register */
  ATM128_OSCCAL  = 0x6F,

/* 2-wire Serial Interface Bit Rate Register */
  ATM128_TWBR    = 0x70,

/* 2-wire Serial Interface Status Register */
  ATM128_TWSR    = 0x71,

/* 2-wire Serial Interface Address Register */
  ATM128_TWAR    = 0x72,

/* 2-wire Serial Interface Data Register */
  ATM128_TWDR    = 0x73,

/* 2-wire Serial Interface Control Register */
  ATM128_TWCR    = 0x74,

/* Time Counter 1 Output Compare Register C */
  ATM128_OCR1C   = 0x78,
  ATM128_OCR1CL  = 0x78,
  ATM128_OCR1CH  = 0x79,

/* Timer/Counter 1 Control Register C */
  ATM128_TCCR1C  = 0x7A,

/* Extended Timer Interrupt Flag Register */
  ATM128_ETIFR   = 0x7C,

/* Extended Timer Interrupt Mask Register */
  ATM128_ETIMSK  = 0x7D,

/* Timer/Counter 3 Input Capture Register */
  ATM128_ICR3    = 0x80,
  ATM128_ICR3L   = 0x80,
  ATM128_ICR3H   = 0x81,

/* Timer/Counter 3 Output Compare Register C */
  ATM128_OCR3C   = 0x82,
  ATM128_OCR3CL  = 0x82,
  ATM128_OCR3CH  = 0x83,

/* Timer/Counter 3 Output Compare Register B */
  ATM128_OCR3B   = 0x84,
  ATM128_OCR3BL  = 0x84,
  ATM128_OCR3BH  = 0x85,

/* Timer/Counter 3 Output Compare Register A */
  ATM128_OCR3A   = 0x86,
  ATM128_OCR3AL  = 0x86,
  ATM128_OCR3AH  = 0x87,

/* Timer/Counter 3 Counter Register */
  ATM128_TCNT3   = 0x88,
  ATM128_TCNT3L  = 0x88,
  ATM128_TCNT3H  = 0x89,

/* Timer/Counter 3 Control Register B */
  ATM128_TCCR3B  = 0x8A,

/* Timer/Counter 3 Control Register A */
  ATM128_TCCR3A  = 0x8B,

/* Timer/Counter 3 Control Register C */
  ATM128_TCCR3C  = 0x8C,

/* USART0 Baud Rate Register High */
  ATM128_UBRR0H  = 0x90,

/* USART0 Control and Status Register C */
  ATM128_UCSR0C  = 0x95,

/* USART1 Baud Rate Register High */
  ATM128_UBRR1H  = 0x98,

/* USART1 Baud Rate Register Low*/
  ATM128_UBRR1L  = 0x99,

/* USART1 Control and Status Register B */
  ATM128_UCSR1B  = 0x9A,

/* USART1 Control and Status Register A */
  ATM128_UCSR1A  = 0x9B,

/* USART1 I/O Data Register */
  ATM128_UDR1    = 0x9C,

/* USART1 Control and Status Register C */
  ATM128_UCSR1C  = 0x9D,
};

/* Input Pins, Port F */
#define PINF      _SFR_IO8(0x00)

/* Input Pins, Port E */
#define PINE      _SFR_IO8(0x01)

/* Data Direction Register, Port E */
#define DDRE      _SFR_IO8(0x02)

/* Data Register, Port E */
#define PORTE     _SFR_IO8(0x03)

/* ADC Data Register */
#define ADCW      _SFR_IO16(0x04) /* for backwards compatibility */
#ifndef __ASSEMBLER__
#define ADC       _SFR_IO16(0x04)
#endif
#define ADCL      _SFR_IO8(0x04)
#define ADCH      _SFR_IO8(0x05)

/* ADC Control and status register */
#define ADCSR     _SFR_IO8(0x06)
#define ADCSRA    _SFR_IO8(0x06) /* new name in datasheet (2467E-AVR-05/02) */

/* ADC Multiplexer select */
#define ADMUX     _SFR_IO8(0x07)

/* Analog Comparator Control and Status Register */
#define ACSR      _SFR_IO8(0x08)

/* USART0 Baud Rate Register Low */
#define UBRR0L    _SFR_IO8(0x09)

/* USART0 Control and Status Register B */
#define UCSR0B    _SFR_IO8(0x0A)

/* USART0 Control and Status Register A */
#define UCSR0A    _SFR_IO8(0x0B)

/* USART0 I/O Data Register */
#define UDR0      _SFR_IO8(0x0C)

/* SPI Control Register */
#define SPCR      _SFR_IO8(0x0D)

/* SPI Status Register */
#define SPSR      _SFR_IO8(0x0E)

/* SPI I/O Data Register */
#define SPDR      _SFR_IO8(0x0F)

/* Input Pins, Port D */
#define PIND      _SFR_IO8(0x10)

/* Data Direction Register, Port D */
#define DDRD      _SFR_IO8(0x11)

/* Data Register, Port D */
#define PORTD     _SFR_IO8(0x12)

/* Input Pins, Port C */
#define PINC      _SFR_IO8(0x13)

/* Data Direction Register, Port C */
#define DDRC      _SFR_IO8(0x14)

/* Data Register, Port C */
#define PORTC     _SFR_IO8(0x15)

/* Input Pins, Port B */
#define PINB      _SFR_IO8(0x16)

/* Data Direction Register, Port B */
#define DDRB      _SFR_IO8(0x17)

/* Data Register, Port B */
#define PORTB     _SFR_IO8(0x18)

/* Input Pins, Port A */
#define PINA      _SFR_IO8(0x19)

/* Data Direction Register, Port A */
#define DDRA      _SFR_IO8(0x1A)

/* Data Register, Port A */
#define PORTA     _SFR_IO8(0x1B)

/* 0x1C..0x1F EEPROM */

/* Special Function I/O Register */
#define SFIOR     _SFR_IO8(0x20)

/* Watchdog Timer Control Register */
#define WDTCR     _SFR_IO8(0x21)

/* On-chip Debug Register */
#define OCDR      _SFR_IO8(0x22)

/* Timer2 Output Compare Register */
#define OCR2      _SFR_IO8(0x23)

/* Timer/Counter 2 */
#define TCNT2     _SFR_IO8(0x24)

/* Timer/Counter 2 Control register */
#define TCCR2     _SFR_IO8(0x25)

/* T/C 1 Input Capture Register */
#define ICR1      _SFR_IO16(0x26)
#define ICR1L     _SFR_IO8(0x26)
#define ICR1H     _SFR_IO8(0x27)

/* Timer/Counter1 Output Compare Register B */
#define OCR1B     _SFR_IO16(0x28)
#define OCR1BL    _SFR_IO8(0x28)
#define OCR1BH    _SFR_IO8(0x29)

/* Timer/Counter1 Output Compare Register A */
#define OCR1A     _SFR_IO16(0x2A)
#define OCR1AL    _SFR_IO8(0x2A)
#define OCR1AH    _SFR_IO8(0x2B)

/* Timer/Counter 1 */
#define TCNT1     _SFR_IO16(0x2C)
#define TCNT1L    _SFR_IO8(0x2C)
#define TCNT1H    _SFR_IO8(0x2D)

/* Timer/Counter 1 Control and Status Register */
#define TCCR1B    _SFR_IO8(0x2E)

/* Timer/Counter 1 Control Register */
#define TCCR1A    _SFR_IO8(0x2F)

/* Timer/Counter 0 Asynchronous Control & Status Register */
#define ASSR      _SFR_IO8(0x30)

/* Output Compare Register 0 */
#define OCR0      _SFR_IO8(0x31)

/* Timer/Counter 0 */
#define TCNT0     _SFR_IO8(0x32)

/* Timer/Counter 0 Control Register */
#define TCCR0     _SFR_IO8(0x33)

/* MCU Status Register */
#define MCUSR     _SFR_IO8(0x34)
#define MCUCSR    _SFR_IO8(0x34) /* new name in datasheet (2467E-AVR-05/02) */

/* MCU general Control Register */
#define MCUCR     _SFR_IO8(0x35)

/* Timer/Counter Interrupt Flag Register */
#define TIFR      _SFR_IO8(0x36)

/* Timer/Counter Interrupt MaSK register */
#define TIMSK     _SFR_IO8(0x37)

/* External Interrupt Flag Register */
#define EIFR      _SFR_IO8(0x38)

/* External Interrupt MaSK register */
#define EIMSK     _SFR_IO8(0x39)

/* External Interrupt Control Register B */
#define EICRB     _SFR_IO8(0x3A)

/* RAM Page Z select register */
#define RAMPZ     _SFR_IO8(0x3B)

/* XDIV Divide control register */
#define XDIV      _SFR_IO8(0x3C)

/* 0x3D..0x3E SP */

/* 0x3F SREG */
#define SREG      _SFR_IO8(0x3F)

/* Extended I/O registers */

/* Data Direction Register, Port F */
#define DDRF      _SFR_MEM8(0x61)

/* Data Register, Port F */
#define PORTF     _SFR_MEM8(0x62)

/* Input Pins, Port G */
#define PING      _SFR_MEM8(0x63)

/* Data Direction Register, Port G */
#define DDRG      _SFR_MEM8(0x64)

/* Data Register, Port G */
#define PORTG     _SFR_MEM8(0x65)

/* Store Program Memory Control and Status Register */
#define SPMCR     _SFR_MEM8(0x68)
#define SPMCSR    _SFR_MEM8(0x68) /* new name in datasheet (2467E-AVR-05/02) */

/* External Interrupt Control Register A */
#define EICRA     _SFR_MEM8(0x6A)

/* External Memory Control Register B */
#define XMCRB     _SFR_MEM8(0x6C)

/* External Memory Control Register A */
#define XMCRA     _SFR_MEM8(0x6D)

/* Oscillator Calibration Register */
#define OSCCAL    _SFR_MEM8(0x6F)

/* 2-wire Serial Interface Bit Rate Register */
#define TWBR      _SFR_MEM8(0x70)

/* 2-wire Serial Interface Status Register */
#define TWSR      _SFR_MEM8(0x71)

/* 2-wire Serial Interface Address Register */
#define TWAR      _SFR_MEM8(0x72)

/* 2-wire Serial Interface Data Register */
#define TWDR      _SFR_MEM8(0x73)

/* 2-wire Serial Interface Control Register */
#define TWCR      _SFR_MEM8(0x74)

/* Time Counter 1 Output Compare Register C */
#define OCR1C     _SFR_MEM16(0x78)
#define OCR1CL    _SFR_MEM8(0x78)
#define OCR1CH    _SFR_MEM8(0x79)

/* Timer/Counter 1 Control Register C */
#define TCCR1C    _SFR_MEM8(0x7A)

/* Extended Timer Interrupt Flag Register */
#define ETIFR     _SFR_MEM8(0x7C)

/* Extended Timer Interrupt Mask Register */
#define ETIMSK    _SFR_MEM8(0x7D)

/* Timer/Counter 3 Input Capture Register */
#define ICR3      _SFR_MEM16(0x80)
#define ICR3L     _SFR_MEM8(0x80)
#define ICR3H     _SFR_MEM8(0x81)

/* Timer/Counter 3 Output Compare Register C */
#define OCR3C     _SFR_MEM16(0x82)
#define OCR3CL    _SFR_MEM8(0x82)
#define OCR3CH    _SFR_MEM8(0x83)

/* Timer/Counter 3 Output Compare Register B */
#define OCR3B     _SFR_MEM16(0x84)
#define OCR3BL    _SFR_MEM8(0x84)
#define OCR3BH    _SFR_MEM8(0x85)

/* Timer/Counter 3 Output Compare Register A */
#define OCR3A     _SFR_MEM16(0x86)
#define OCR3AL    _SFR_MEM8(0x86)
#define OCR3AH    _SFR_MEM8(0x87)

/* Timer/Counter 3 Counter Register */
#define TCNT3     _SFR_MEM16(0x88)
#define TCNT3L    _SFR_MEM8(0x88)
#define TCNT3H    _SFR_MEM8(0x89)

/* Timer/Counter 3 Control Register B */
#define TCCR3B    _SFR_MEM8(0x8A)

/* Timer/Counter 3 Control Register A */
#define TCCR3A    _SFR_MEM8(0x8B)

/* Timer/Counter 3 Control Register C */
#define TCCR3C    _SFR_MEM8(0x8C)

/* USART0 Baud Rate Register High */
#define UBRR0H    _SFR_MEM8(0x90)

/* USART0 Control and Status Register C */
#define UCSR0C    _SFR_MEM8(0x95)

/* USART1 Baud Rate Register High */
#define UBRR1H    _SFR_MEM8(0x98)

/* USART1 Baud Rate Register Low*/
#define UBRR1L    _SFR_MEM8(0x99)

/* USART1 Control and Status Register B */
#define UCSR1B    _SFR_MEM8(0x9A)

/* USART1 Control and Status Register A */
#define UCSR1A    _SFR_MEM8(0x9B)

/* USART1 I/O Data Register */
#define UDR1      _SFR_MEM8(0x9C)

/* USART1 Control and Status Register C */
#define UCSR1C    _SFR_MEM8(0x9D)

/* Interrupt vectors */

#define _VECTOR(x) INTERRUPT_##x

#define SIG_INTERRUPT0          _VECTOR(1)
#define SIG_INTERRUPT1          _VECTOR(2)
#define SIG_INTERRUPT2          _VECTOR(3)
#define SIG_INTERRUPT3          _VECTOR(4)
#define SIG_INTERRUPT4          _VECTOR(5)
#define SIG_INTERRUPT5          _VECTOR(6)
#define SIG_INTERRUPT6          _VECTOR(7)
#define SIG_INTERRUPT7          _VECTOR(8)
#define SIG_OUTPUT_COMPARE2     _VECTOR(9)
#define SIG_OVERFLOW2           _VECTOR(10)
#define SIG_INPUT_CAPTURE1      _VECTOR(11)
#define SIG_OUTPUT_COMPARE1A    _VECTOR(12)
#define SIG_OUTPUT_COMPARE1B    _VECTOR(13)
#define SIG_OVERFLOW1           _VECTOR(14)
#define SIG_OUTPUT_COMPARE0     _VECTOR(15)
#define SIG_OVERFLOW0           _VECTOR(16)
#define SIG_SPI                 _VECTOR(17)
#define SIG_USART0_RECV         _VECTOR(18)
#define SIG_UART0_RECV          _VECTOR(18) /* Keep for compatibility */
#define SIG_USART0_DATA         _VECTOR(19)
#define SIG_UART0_DATA          _VECTOR(19) /* Keep for compatibility */
#define SIG_USART0_TRANS        _VECTOR(20)
#define SIG_UART0_TRANS         _VECTOR(20) /* Keep for compatibility */
#define SIG_ADC                 _VECTOR(21)
#define SIG_EEPROM_READY        _VECTOR(22)
#define SIG_COMPARATOR          _VECTOR(23)
#define SIG_OUTPUT_COMPARE1C    _VECTOR(24)
#define SIG_INPUT_CAPTURE3      _VECTOR(25)
#define SIG_OUTPUT_COMPARE3A    _VECTOR(26)
#define SIG_OUTPUT_COMPARE3B    _VECTOR(27)
#define SIG_OUTPUT_COMPARE3C    _VECTOR(28)
#define SIG_OVERFLOW3           _VECTOR(29)
#define SIG_USART1_RECV         _VECTOR(30)
#define SIG_UART1_RECV          _VECTOR(30) /* Keep for compatibility */
#define SIG_USART1_DATA         _VECTOR(31)
#define SIG_UART1_DATA          _VECTOR(31) /* Keep for compatibility */
#define SIG_USART1_TRANS        _VECTOR(32)
#define SIG_UART1_TRANS         _VECTOR(32) /* Keep for compatibility */
#define SIG_2WIRE_SERIAL        _VECTOR(33)
#define SIG_SPM_READY           _VECTOR(34)

#define _VECTORS_SIZE 140

/*
   The Register Bit names are represented by their bit number (0-7).
*/
enum {
/* 2-wire Control Register - TWCR */
  TWINT  = 7,
  TWEA   = 6,
  TWSTA  = 5,
  TWSTO  = 4,
  TWWC   = 3,
  TWEN   = 2,
  TWIE   = 0,

/* 2-wire Address Register - TWAR */
  TWA6   = 7,
  TWA5   = 6,
  TWA4   = 5,
  TWA3   = 4,
  TWA2   = 3,
  TWA1   = 2,
  TWA0   = 1,
  TWGCE  = 0,

/* 2-wire Status Register - TWSR */
  TWS7   = 7,
  TWS6   = 6,
  TWS5   = 5,
  TWS4   = 4,
  TWS3   = 3,
  TWPS1  = 1,
  TWPS0  = 0,

/* External Memory Control Register A - XMCRA */
  SRL2   = 6,
  SRL1   = 5,
  SRL0   = 4,
  SRW01  = 3,
  SRW00  = 2,
  SRW11  = 1,

/* External Memory Control Register B - XMCRA */
  XMBK   = 7,
  XMM2   = 2,
  XMM1   = 1,
  XMM0   = 0,

/* XDIV Divide control register - XDIV */
  XDIVEN = 7,
  XDIV6  = 6,
  XDIV5  = 5,
  XDIV4  = 4,
  XDIV3  = 3,
  XDIV2  = 2,
  XDIV1  = 1,
  XDIV0  = 0,

/* RAM Page Z select register - RAMPZ */
  RAMPZ0= 0,

/* External Interrupt Control Register A - EICRA */
  ISC31  = 7,
  ISC30  = 6,
  ISC21  = 5,
  ISC20  = 4,
  ISC11  = 3,
  ISC10  = 2,
  ISC01  = 1,
  ISC00  = 0,

/* External Interrupt Control Register B - EICRB */
  ISC71  = 7,
  ISC70  = 6,
  ISC61  = 5,
  ISC60  = 4,
  ISC51  = 3,
  ISC50  = 2,
  ISC41  = 1,
  ISC40  = 0,

/* Store Program Memory Control Register - SPMCSR, SPMCR */
  SPMIE  = 7,
  RWWSB  = 6,
  RWWSRE = 4,
  BLBSET = 3,
  PGWRT  = 2,
  PGERS  = 1,
  SPMEN  = 0,

/* External Interrupt MaSK register - EIMSK */
  INT7   = 7,
  INT6   = 6,
  INT5   = 5,
  INT4   = 4,
  INT3   = 3,
  INT2   = 2,
  INT1   = 1,
  INT0   = 0,

/* External Interrupt Flag Register - EIFR */
  INTF7  = 7,
  INTF6  = 6,
  INTF5  = 5,
  INTF4  = 4,
  INTF3  = 3,
  INTF2  = 2,
  INTF1  = 1,
  INTF0  = 0,

/* Timer/Counter Interrupt MaSK register - TIMSK */
  OCIE2  = 7,
  TOIE2  = 6,
  TICIE1 = 5,
  OCIE1A = 4,
  OCIE1B = 3,
  TOIE1  = 2,
  OCIE0  = 1,
  TOIE0  = 0,

/* Timer/Counter Interrupt Flag Register - TIFR */
  OCF2   = 7,
  TOV2   = 6,
  ICF1   = 5,
  OCF1A  = 4,
  OCF1B  = 3,
  TOV1   = 2,
  OCF0   = 1,
  TOV0   = 0,

/* Extended Timer Interrupt MaSK register - ETIMSK */
  TICIE3 = 5,
  OCIE3A = 4,
  OCIE3B = 3,
  TOIE3  = 2,
  OCIE3C = 1,
  OCIE1C = 0,

/* Extended Timer Interrupt Flag Register - ETIFR */
  ICF3  =  5,
  OCF3A =  4,
  OCF3B =  3,
  TOV3  =  2,
  OCF3C =  1,
  OCF1C =  0,

/* MCU general Control Register - MCUCR */
  SRE   =  7,
  SRW   =  6,
  SRW10 =  6,      /* new name in datasheet (2467E-AVR-05/02) */
  SE    =  5,
  SM1   =  4,
  SM0   =  3,
  SM2   =  2,
  IVSEL =  1,
  IVCE  =  0,

/* MCU Status Register - MCUSR, MCUCSR */
  JTD  =   7,
  JTRF =   4,
  WDRF =   3,
  BORF =   2,
  EXTRF=   1,
  PORF =   0,

/* Timer/Counter Control Register (generic) */
  FOC   =  7,
  WGM0  =  6,
  COM1  =  5,
  COM0  =  4,
  WGM1  =  3,
  CS2   =  2,
  CS1   =  1,
  CS0   =  0,

/* Timer/Counter 0 Control Register - TCCR0 */
  FOC0  =  7,
  WGM00 =  6,
  COM01 =  5,
  COM00 =  4,
  WGM01 =  3,
  CS02  =  2,
  CS01  =  1,
  CS00  =  0,

/* Timer/Counter 2 Control Register - TCCR2 */
  FOC2   = 7,
  WGM20  = 6,
  COM21  = 5,
  COM20  = 4,
  WGM21  = 3,
  CS22   = 2,
  CS21   = 1,
  CS20   = 0,

/* Timer/Counter 0 Asynchronous Control & Status Register - ASSR */
  AS0    = 3,
  TCN0UB = 2,
  OCR0UB = 1,
  TCR0UB = 0,
  
/* Timer/Counter Control Register A (generic) */
  COMA1 =  7,
  COMA0 =  6,
  COMB1 =  5,
  COMB0 =  4,
  COMC1 =  3,
  COMC0 =  2,
  WGMA1 =  1,
  WGMA0 =  0,

/* Timer/Counter 1 Control and Status Register A - TCCR1A */
  COM1A1=  7,
  COM1A0=  6,
  COM1B1=  5,
  COM1B0=  4,
  COM1C1=  3,
  COM1C0=  2,
  WGM11 =  1,
  WGM10 =  0,

/* Timer/Counter 3 Control and Status Register A - TCCR3A */
  COM3A1=  7,
  COM3A0=  6,
  COM3B1=  5,
  COM3B0=  4,
  COM3C1=  3,
  COM3C0=  2,
  WGM31 =  1,
  WGM30 =  0,

/* Timer/Counter Control and Status Register B (generic) */
  ICNC  =  7,
  ICES  =  6,
  WGMB3 =  4,
  WGMB2 =  3,
  CSB2  =  2,
  CSB1  =  1,
  CSB0  =  0,

/* Timer/Counter 1 Control and Status Register B - TCCR1B */
  ICNC1 =  7,
  ICES1 =  6,
  WGM13 =  4,
  WGM12 =  3,
  CS12  =  2,
  CS11  =  1,
  CS10  =  0,

/* Timer/Counter 3 Control and Status Register B - TCCR3B */
  ICNC3 =  7,
  ICES3 =  6,
  WGM33 =  4,
  WGM32 =  3,
  CS32  =  2,
  CS31  =  1,
  CS30  =  0,

/* Timer/Counter Control Register C (generic) */
  FOCA  =  7,
  FOCB  =  6,
  FOCC  =  5,

/* Timer/Counter 3 Control Register C - TCCR3C */
  FOC3A =  7,
  FOC3B =  6,
  FOC3C =  5,

/* Timer/Counter 1 Control Register C - TCCR1C */
  FOC1A =  7,
  FOC1B =  6,
  FOC1C =  5,

/* On-chip Debug Register - OCDR */
  IDRD  =  7,
  OCDR7 =  7,
  OCDR6 =  6,
  OCDR5 =  5,
  OCDR4 =  4,
  OCDR3 =  3,
  OCDR2 =  2,
  OCDR1 =  1,
  OCDR0 =  0,
  
/* Watchdog Timer Control Register - WDTCR */
  WDCE  =  4,
  WDE   =  3,
  WDP2  =  2,
  WDP1  =  1,
  WDP0  =  0,

/* Special Function I/O Register - SFIOR */
  TSM   =  7,
  ADHSM =  4,
  ACME  =  3,
  PUD   =  2,
  PSR0  =  1,
  PSR321=  0,

/* SPI Status Register - SPSR */
  SPIF  =  7,
  WCOL  =  6,
  SPI2X =  0,

/* SPI Control Register - SPCR */
  SPIE   = 7,
  SPE    = 6,
  DORD   = 5,
  MSTR   = 4,
  CPOL   = 3,
  CPHA   = 2,
  SPR1   = 1,
  SPR0   = 0,

/* USART Register C (generic) */
  UMSEL  = 6,
  UPM1   = 5,
  UPM0   = 4,
  USBS   = 3,
  UCSZ1  = 2,
  UCSZ0  = 1,
  UCPOL  = 0,

/* USART1 Register C - UCSR1C */
  UMSEL1 = 6,
  UPM11  = 5,
  UPM10  = 4,
  USBS1  = 3,
  UCSZ11 = 2,
  UCSZ10 = 1,
  UCPOL1 = 0,

/* USART0 Register C - UCSR0C */
  UMSEL0 = 6,
  UPM01  = 5,
  UPM00  = 4,
  USBS0  = 3,
  UCSZ01 = 2,
  UCSZ00 = 1,
  UCPOL0 = 0,

/* USART Status Register A (generic) */
  RXC   =  7,
  TXC   =  6,
  UDRE  =  5,
  FE    =  4,
  DOR   =  3,
  UPE   =  2,
  U2X   =  1,
  MPCM  =  0,

/* USART1 Status Register A - UCSR1A */
  RXC1  =  7,
  TXC1  =  6,
  UDRE1 =  5,
  FE1   =  4,
  DOR1  =  3,
  UPE1  =  2,
  U2X1  =  1,
  MPCM1 =  0,

/* USART0 Status Register A - UCSR0A */
  RXC0  =  7,
  TXC0  =  6,
  UDRE0 =  5,
  FE0   =  4,
  DOR0  =  3,
  UPE0  =  2,
  U2X0  =  1,
  MPCM0 =  0,

/* USART Control Register B (generic) */
  RXCIE =  7,
  TXCIE =  6,
  UDRIE =  5,
  RXEN  =  4,
  TXEN  =  3,
  UCSZ  =  2,
  UCSZ2 =  2,      /* new name in datasheet (2467E-AVR-05/02) */
  RXB8  =  1,
  TXB8  =  0,

/* USART1 Control Register B - UCSR1B */
  RXCIE1 = 7,
  TXCIE1 = 6,
  UDRIE1 = 5,
  RXEN1  = 4,
  TXEN1  = 3,
  UCSZ12 = 2,
  RXB81  = 1,
  TXB81  = 0,

/* USART0 Control Register B - UCSR0B */
  RXCIE0 = 7,
  TXCIE0 = 6,
  UDRIE0 = 5,
  RXEN0  = 4,
  TXEN0  = 3,
  UCSZ02 = 2,
  RXB80  = 1,
  TXB80  = 0,

/* Analog Comparator Control and Status Register - ACSR */
  ACD    = 7,
  ACBG   = 6,
  ACO    = 5,
  ACI    = 4,
  ACIE   = 3,
  ACIC   = 2,
  ACIS1  = 1,
  ACIS0  = 0,

/* ADC Control and status register - ADCSRA */
  ADEN  =  7,
  ADSC  =  6,
  ADFR  =  5,
  ADIF  =  4,
  ADIE  =  3,
  ADPS2 =  2,
  ADPS1 =  1,
  ADPS0 =  0,

/* ADC Multiplexer select - ADMUX */
  REFS1 =  7,
  REFS0 =  6,
  ADLAR =  5,
  MUX4  =  4,
  MUX3  =  3,
  MUX2  =  2,
  MUX1  =  1,
  MUX0  =  0,

/* Port A Data Register - PORTA */
  PA7 = 7,
  PA6 = 6,
  PA5 = 5,
  PA4 = 4,
  PA3 = 3,
  PA2 = 2,
  PA1 = 1,
  PA0 = 0,

/* Port A Data Direction Register - DDRA */
  DDA7 =   7,
  DDA6 =   6,
  DDA5 =   5,
  DDA4 =   4,
  DDA3 =   3,
  DDA2 =   2,
  DDA1 =   1,
  DDA0 =   0,

/* Port A Input Pins - PINA */
  PINA7 =  7,
  PINA6 =  6,
  PINA5 =  5,
  PINA4 =  4,
  PINA3 =  3,
  PINA2 =  2,
  PINA1 =  1,
  PINA0 =  0,

/* Port B Data Register - PORTB */
  PB7 = 7,
  PB6 = 6,
  PB5 = 5,
  PB4 = 4,
  PB3 = 3,
  PB2 = 2,
  PB1 = 1,
  PB0 = 0,

/* Port B Data Direction Register - DDRB */
  DDB7 =   7,
  DDB6 =   6,
  DDB5 =   5,
  DDB4 =   4,
  DDB3 =   3,
  DDB2 =   2,
  DDB1 =   1,
  DDB0 =   0,

/* Port B Input Pins - PINB */
  PINB7 =  7,
  PINB6 =  6,
  PINB5 =  5,
  PINB4 =  4,
  PINB3 =  3,
  PINB2 =  2,
  PINB1 =  1,
  PINB0 =  0,

/* Port C Data Register - PORTC */
  PC7 = 7,
  PC6 = 6,
  PC5 = 5,
  PC4 = 4,
  PC3 = 3,
  PC2 = 2,
  PC1 = 1,
  PC0 = 0,

/* Port C Data Direction Register - DDRC */
  DDC7 =   7,
  DDC6 =   6,
  DDC5 =   5,
  DDC4 =   4,
  DDC3 =   3,
  DDC2 =   2,
  DDC1 =   1,
  DDC0 =   0,

/* Port C Input Pins - PINC */
  PINC7=   7,
  PINC6=   6,
  PINC5 =  5,
  PINC4 =  4,
  PINC3 =  3,
  PINC2 =  2,
  PINC1 =  1,
  PINC0 =  0,

/* Port D Data Register - PORTD */
  PD7 = 7,
  PD6 = 6,
  PD5 = 5,
  PD4 = 4,
  PD3 = 3,
  PD2 = 2,
  PD1 = 1,
  PD0 = 0,

/* Port D Data Direction Register - DDRD */
  DDD7 =   7,
  DDD6 =   6,
  DDD5 =   5,
  DDD4 =   4,
  DDD3 =   3,
  DDD2 =   2,
  DDD1 =   1,
  DDD0 =   0,

/* Port D Input Pins - PIND */
  PIND7 =  7,
  PIND6 =  6,
  PIND5 =  5,
  PIND4 =  4,
  PIND3 =  3,
  PIND2 =  2,
  PIND1 =  1,
  PIND0 =  0,

/* Port E Data Register - PORTE */
  PE7 = 7,
  PE6 = 6,
  PE5 = 5,
  PE4 = 4,
  PE3 = 3,
  PE2 = 2,
  PE1 = 1,
  PE0 = 0,

/* Port E Data Direction Register - DDRE */
  DDE7  =  7,
  DDE6  =  6,
  DDE5  =  5,
  DDE4  =  4,
  DDE3  =  3,
  DDE2  =  2,
  DDE1  =  1,
  DDE0  =  0,

/* Port E Input Pins - PINE */
  PINE7 =  7,
  PINE6 =  6,
  PINE5 =  5,
  PINE4 =  4,
  PINE3 =  3,
  PINE2 =  2,
  PINE1 =  1,
  PINE0 =  0,

/* Port F Data Register - PORTF */
  PF7 = 7,
  PF6 = 6,
  PF5 = 5,
  PF4 = 4,
  PF3 = 3,
  PF2 = 2,
  PF1 = 1,
  PF0 = 0,

/* Port F Data Direction Register - DDRF */
  DDF7   = 7,
  DDF6   = 6,
  DDF5   = 5,
  DDF4   = 4,
  DDF3   = 3,
  DDF2   = 2,
  DDF1   = 1,
  DDF0   = 0,

/* Port F Input Pins - PINF */
  PINF7  = 7,
  PINF6  = 6,
  PINF5  = 5,
  PINF4  = 4,
  PINF3  = 3,
  PINF2  = 2,
  PINF1  = 1,
  PINF0  = 0,

/* Port G Data Register - PORTG */
  PG4    = 4,
  PG3    = 3,
  PG2    = 2,
  PG1    = 1,
  PG0    = 0,

/* Port G Data Direction Register - DDRG */
  DDG4   = 4,
  DDG3   = 3,
  DDG2   = 2,
  DDG1   = 1,
  DDG0   = 0,

/* Port G Input Pins - PING */
  PING4  = 4,
  PING3  = 3,
  PING2  = 2,
  PING1  = 1,
  PING0  = 0,
};


#endif
