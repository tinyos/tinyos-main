/*
 * Copyright (c) 2005
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* 
 * Writes printf like output to the UART.  
 * This works only on the AVR and MSP430 Microcontrollers!
 * <p>
 * Note: For AVR we explicitly place the print statements in ROM; for
 * MSP430 this is done by default!  For AVR, if we don't place it
 * explicitely in ROM, the statements will go in RAM, which will
 * quickly cause a descent size program to run out of RAM.  By default
 * it doesn't disable the interupts; disabling the interupts when
 * writing to the UART, slows down/makes the mote quite unresponsive,
 * and can lead to problems!  If you wish to disable all printfs to
 * the UART, then comment the flag: <code>PRINTFUART_ENABLED</code>.

 * <p> <pre>
 * How to use:
 *   // (1) Call printfUART_init() from your initialization function 
 *   //     to initialize the UART
 *   printfUART_init();
 *   // (2) Set your UART client to the correct baud rate.  Look at 
 *   //     the comments in printfUART_init(), to figure out what 
 *   //     baud to use for your particular mote
 *
 *   // (3) Send printf statements like this:
 *   printfUART("Hello World, we are in year= %i\n", 2004);
 *
 * Examples and caveats:
 *   // (1) - If no parameters are passed, then the second quotes 
 *            are required because of how the macro is defined
 *   printfUART("Timer fired\n", ""); 
 *   // (2) - Must use curly braces in single section statements
 *   if (x < 3)
 *       {printfUART("The value of x is %i\n", x);}
 *   // (3) - Otherwise it more or less works like regular printf
 *   printfUART("\nThe value of x=%i, and y=%i\n", x, y); 
 * </pre>
 * <pre>URL: http://www.eecs.harvard.edu/~konrad/projects/motetrack</pre>
 * @author Konrad Lorincz
 * @version 2.0, January 5, 2005
 */
#ifndef PRINTFUART_H
#define PRINTFUART_H
#include <stdarg.h>
//#include <stdio.h>

// Comment out the line below to DISABLE printf statements.
//#define PRINTFUART_ENABLED


// -------------------------------------------------------------------
#ifdef PRINTFUART_ENABLED
    #define DEBUGBUF_SIZE 256
    char debugbuf[DEBUGBUF_SIZE];
    char debugbufROMtoRAM[DEBUGBUF_SIZE];

    #if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
        #define printfUART(__format, __args...) {                  \
            static const char strROM[] PROGMEM = __format;         \
            strcpy_P((char*) &debugbufROMtoRAM, (PGM_P) &strROM);  \
            sprintf(debugbuf, debugbufROMtoRAM, __args);           \
            writedebug();                                          \
        }   
    #else  // assume MSP430 architecture (e.g. TelosA, TelosB, etc.)
        #define printfUART(__format, __args...) {      \
            sprintf(debugbuf, __format, __args);       \
            writedebug();                              \
        }   
    #endif
#else
    #define printfUART(__format, __args...)
    void printfUART_init() {}
#endif

#define NOprintfUART(__format, __args...)


/** Used for terminating the program from a non-nesc file. Calling <code>exit(1)</code> 
 *  from a non-nesc file doesn't terminate the program immeditely
 */
static int EXIT_PROGRAM = 0;  



// -------------------------------------------------------------------
#ifdef PRINTFUART_ENABLED

/**
 * Initialize the UART port.  Call this from your startup routine.
 */
#define printfUART_init() {atomic printfUART_init_private();}
void printfUART_init_private()
{
    #if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2)
        // 56K baud
        outp(0,UBRR0H);
        outp(15, UBRR0L);                              //set baud rate
        outp((1<<U2X),UCSR0A);                         // Set UART double speed
        outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);  // Set frame format: 8 data-bits, 1 stop-bit
        inp(UDR0);
        outp((1 << TXEN) ,UCSR0B);   // Enable uart reciever and transmitter

    #else
      #if defined(PLATFORM_MICA2DOT)  
        // 19.2K baud
        outp(0,UBRR0H);            // Set baudrate to 19.2 KBps
        outp(12, UBRR0L);
        outp(0,UCSR0A);            // Disable U2X and MPCM
        outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);
        inp(UDR0);
        outp((1 << TXEN) ,UCSR0B);
  
      #else  // assume TelosA, TelosB, etc.
        //9.6K baud
        uint16_t l_br = 0;
        uint8_t l_mctl = 0;
        uint8_t l_ssel = 0;


        TOSH_SEL_UTXD1_MODFUNC();
        TOSH_SEL_URXD1_MODFUNC();


        UCTL1 = SWRST;  
        UCTL1 |= CHAR;  // 8-bit char, UART-mode
    
        U1RCTL &= ~URXEIE;  // even erroneous characters trigger interrupts

        UCTL1 = SWRST;
        UCTL1 |= CHAR;  // 8-bit char, UART-mode

        if (l_ssel & 0x80) {
            U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
            U1TCTL |= (l_ssel & 0x7F); 
        }
        else {
            U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
            U1TCTL |= SSEL_ACLK; // use ACLK, assuming 32khz
        }

        if ((l_mctl != 0) || (l_br != 0)) {
            U1BR0 = l_br & 0x0FF;
            U1BR1 = (l_br >> 8) & 0x0FF;
            U1MCTL = l_mctl;
        }
        else {
            U1BR0 = 0x03;   // 9600 baud
            U1BR1 = 0x00;
            U1MCTL = 0x4A;
        }
      
        ME2 &= ~USPIE1;   // USART1 SPI module disable
        ME2 |= (UTXE1 | URXE1);   // USART1 UART module enable
      
        U1CTL &= ~SWRST;
    
        IFG2 &= ~(UTXIFG1 | URXIFG1);
        IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disabled

      #endif
    #endif
}

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
#else // assume AVR architecture (e.g. TelosA, TelosB)
    bool isTxIntrPending()
    {
        if (U1TCTL & TXEPT) {
            return TRUE;
        }
        return FALSE;
    }
#endif

/**
 * Outputs a char to the UART.
 */
void UARTPutChar(char c)
{
    if (c == '\n')
        UARTPutChar('\r');


    #if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
        loop_until_bit_is_set(UCSR0A, UDRE);
        outb(UDR0,c);
    #else // assume AVR architecture (e.g. TelosA, TelosB)
        U1TXBUF = c;  
        while( !isTxIntrPending() )  
            continue;
    #endif
}

/**
 * Outputs the entire debugbuf to the UART, or until it encounters '\0'.
 */
void writedebug()
{
    uint16_t i = 0;
    
    while (debugbuf[i] != '\0' && i < DEBUGBUF_SIZE)
        UARTPutChar(debugbuf[i++]);
}



/**
 * Simplified sprintf
 */
#define SCRATCH 16
int sprintf(uint8_t *buf, const uint8_t *format, ...)
{
    uint8_t scratch[SCRATCH];
    uint8_t format_flag;
    uint32_t u_val=0, base;//modified by Andre Cunha
    uint8_t *ptr;
    va_list ap;

   //memset(scratch, 0, SCRATCH);
	
    buf[0] = '\0';  // KLDEBUG - fixes subtle bug ...
    va_start (ap, format);
    for (;;){
        while ((format_flag = *format++) != '%'){      // Until '%' or '\0'
            if (!format_flag) {va_end (ap); return (0);}
            *buf = format_flag; buf++; *buf=0;
        }

        switch (format_flag = *format++){

        case 'c':
            format_flag = va_arg(ap,int);
        default:
            *buf = format_flag; buf++; *buf=0;
            continue;
        case 'S':
        case 's':
            ptr = va_arg(ap,char *);
            strcat(buf, ptr);
            continue;
        case 'o':
            base = 8;
            *buf = '0'; buf++; *buf=0;
            goto CONVERSION_LOOP;
        case 'i':
            if (((int)u_val) < 0){
                u_val = - u_val;
                *buf = '-'; buf++; *buf=0;
            }
			base = 10;
            goto CONVERSION_LOOP;
            // no break -> run into next case
		 case 'd'://added by Andre Cunha
            if (((int32_t)u_val) < 0){
                u_val = - u_val;
                *buf = '-'; buf++; *buf=0;
            }
            
			base = 10;
            goto CONVERSION_LOOP32;
        case 'u':
            base = 10;
            goto CONVERSION_LOOP;
        case 'x':
            base = 16;
			goto CONVERSION_LOOP;
			
		case 'y'://unsigned int 32 bits hexadecimal//added by Andre Cunha
            base = 16;
			goto CONVERSION_LOOP32;
			
        CONVERSION_LOOP:
            u_val = va_arg(ap,int);
            ptr = scratch + SCRATCH;
            *--ptr = 0;
            do {
                char ch = u_val % base + '0';
                if (ch > '9')
                    ch += 'a' - '9' - 1;
                *--ptr = ch;
                u_val /= base;
            } while (u_val);
            strcat(buf, ptr);
            buf += strlen(ptr);
			break;
			
		CONVERSION_LOOP32:
            u_val = va_arg(ap,int32_t);
            ptr = scratch + SCRATCH;
            *--ptr = 0;
            do {
                char ch = u_val % base + '0';
                if (ch > '9')
                    ch += 'a' - '9' - 1;
                *--ptr = ch;
                u_val /= base;
            } while (u_val);
            strcat(buf, ptr);
            buf += strlen(ptr);
        }
    }
}


#endif  // PRINTFUART_ENABLED
// -------------------------------------------------------------------

#endif  // PRINTFUART_H

