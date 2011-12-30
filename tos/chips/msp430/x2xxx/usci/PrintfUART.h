/**
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
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
 *   // (0) In your Makefile, define PRINTFUART_ENABLED
 *   CFLAGS += -DPRINTFUART_ENABLED
 *   // (1) Call printfUART_init() from your initialization function 
 *   //     to initialize the UART
 *   printfUART_init();
 *   // (2) Set your UART client to the correct baud rate.  Look at 
 *   //     the comments in printfUART_init(), to figure out what 
 *   //     baud to use for your particular mote
 *
 *   // (3) Send printf statements like this:
 *   printfUART("Hello World, we are in year= %u\n", 2004);
 *   printfUART("Printing uint32_t variable, value= %lu\n", 4294967295);
 *
 * Examples and caveats:
 *   // (1) - Must use curly braces in single section statements.  
 *            (Look in the app.c to see why -- hint: it's a macro)
 *   if (x < 3)
 *       {printfUART("The value of x is %i\n", x);}
 *   // (2) - Otherwise it more or less works like regular printf
 *   printfUART("\nThe value of x=%u, and y=%u\n", x, y); 
 * </pre>
 * <pre>URL: http://www.eecs.harvard.edu/~konrad/projects/motetrack</pre>
 * @author Konrad Lorincz
 * @author Xavier Orduña <xorduna@dexmatech.com>
 * @author Jordi Soucheiron <jsoucheiron@dexmatech.com>
 */

#ifndef PRINTFZ1_H
#define PRINTFZ1_H
#ifndef PRINTFUART_H
#define PRINTFUART_H
#include <stdarg.h>
#include <stdio.h>

#warning including printfZ1

// -------------------------------------------------------------------
#ifdef PRINTFUART_ENABLED
    #define DEBUGBUF_SIZE 256
    char debugbuf[DEBUGBUF_SIZE];
    char debugbufROMtoRAM[DEBUGBUF_SIZE];

    #if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
        #define printfUART(__format...) {                          \
            static const char strROM[] PROGMEM = __format;         \
            strcpy_P((char*) &debugbufROMtoRAM, (PGM_P) &strROM);  \
            sprintf(debugbuf, debugbufROMtoRAM);                   \
            writedebug();                                          \
        }   
    #else  // assume MSP430 architecture (e.g. TelosA, TelosB, etc.)
        #define printfUART(__format...) {      \
            sprintf(debugbuf, __format);       \
            writedebug();                      \
        }  
        #define printfz1(__format...) {      \
	    snprintf(debugbuf,DEBUGBUF_SIZE, __format);       \
            writedebug();                      \
        }  
    #endif
#else
    #define printfz1(X, args...) dbg("printf", X, ## args)
    #define printfUART(X, args...) dbg("printf", X, ## args)
// #define printfUART(__format...) {}
    void printfz1_init() {}
    void printfUART_init() {}
#endif

#define NOprintfUART(__format...)


// -------------------------------------------------------------------
#ifdef PRINTFUART_ENABLED

/**
 * Initialize the UART port.  Call this from your startup routine.
 */
#define printfz1_init() {atomic printfUART_init_private();}
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
  
    #else
    #if defined(PLATFORM_IMOTE2)
      //async command result_t UART.init() {
        
        /*** 
           need to configure the ST UART pins for the correct functionality
           
           GPIO<46> = STDRXD = ALT2(in)
           GPIO<47> = STDTXD = ALT1(out)
        *********/
        //atomic{
          
        //configure the GPIO Alt functions and directions
        _GPIO_setaltfn(46,2);   // STD_RXD
        _GPIO_setaltfn(47,1);   // STD_TXD
        
        _GPDR(46) &= ~_GPIO_bit(46);  // input
        _GPDR(47) |= _GPIO_bit(47);   // output
        
        STLCR |=LCR_DLAB; //turn on DLAB so we can change the divisor
        STDLL = 8;  //configure to 115200;
        STDLH = 0;
        STLCR &= ~(LCR_DLAB);  //turn off DLAB
        
        STLCR |= 0x3; //configure to 8 bits
        
        STMCR &= ~MCR_LOOP;
        STMCR |= MCR_OUT2;
        STIER |= IER_RAVIE;
        STIER |= IER_TIE;
        STIER |= IER_UUE; //enable the UART
        
        //STMCR |= MCR_AFE; //Auto flow control enabled;
        //STMCR |= MCR_RTS;
        
        STFCR |= FCR_TRFIFOE; //enable the fifos
        
//        call Interrupt.allocate();
//        call Interrupt.enable();
        //configure all the interrupt stuff
        //make sure that the interrupt causes an IRQ not an FIQ
        // __REG(0x40D00008) &= ~(1<<21);
        //configure the priority as IPR1
        //__REG(0x40D00020) = (1<<31 | 21);
        //unmask the interrupt
        //__REG(0x40D00004) |= (1<<21);
        
        CKEN |= CKEN5_STUART; //enable the UART's clk    
    #else
    #if defined(PLATFORM_Z1)
                P3SEL |= 0x30;                             // P3.4,5 = USCI_A1 TXD/RXD
                UCA0CTL1 |= UCSSEL_2;                     // CLK = ACLK
                UCA0BR0 = 0x45;                           // 32kHz/9600 = 3.41
                UCA0BR1 = 0x00;                           //
                UCA0MCTL = UCBRS1 + UCBRS0;               // Modulation UCBRSx = 3
                UCA0CTL1 &= ~UCSWRST;                     // **Initialize USCI state machine**

    #else  // assume TelosA, TelosB, etc.
        // Variabel baud 
        // To change the baud rate, see /tos/platform/msp430/msp430baudrates.h
        uint8_t source = SSEL_SMCLK;
        uint16_t baudrate = 0x0012; // UBR_SMCLK_57600=0x0012
        uint8_t mctl = 0x84;        // UMCTL_SMCLK_57600=0x84
        //uint16_t baudrate = 0x0009; // UBR_SMCLK_115200=0x0009
        //uint8_t mctl = 0x10;        // UMCTL_SMCLK_115200=0x10


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

   

        //async command void USARTControl.setClockSource(uint8_t source) {
        //    atomic {
                l_ssel = source | 0x80;
                U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
                U1TCTL |= (l_ssel & 0x7F); 
                //    }
                //}
                //async command void USARTControl.setClockRate(uint16_t baudrate, uint8_t mctl) {
                //atomic {
                l_br = baudrate;
                l_mctl = mctl;
                U1BR0 = baudrate & 0x0FF;
                U1BR1 = (baudrate >> 8) & 0x0FF;
                U1MCTL = mctl;
                //}
                //}

                //async command result_t USARTControl.enableRxIntr(){
                //atomic {
                IFG2 &= ~URXIFG1;
                IE2 |= URXIE1;
                //}
                //return SUCCESS;
                //}

                //async command result_t USARTControl.enableTxIntr(){
                //atomic {
                IFG2 &= ~UTXIFG1;
                IE2 |= UTXIE1;
                //}
                //return SUCCESS;
                //}     

    #endif
    #endif
    #endif
    #endif
}

#if defined(PLATFORM_MICAZ) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
#else
#if defined(PLATFORM_IMOTE2)
#else
#if defined(PLATFORM_Z1)
#else // assume AVR architecture (e.g. TelosA, TelosB)
    bool isTxIntrPending()
    {
        if (U1TCTL & TXEPT) {
            return TRUE;
        }
        return FALSE;
    }
#endif
#endif
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

    #else
    #if defined(PLATFORM_IMOTE2)
        STTHR = c;    
    #else
    #if defined(PLATFORM_Z1)
        while (!(IFG2&UCA0TXIFG));
                atomic UCA0TXBUF = c;

    #else // assume AVR architecture (e.g. TelosA, TelosB)
        U1TXBUF = c;  
        while( !isTxIntrPending() )  
            continue;
    #endif
    #endif
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

#endif  // PRINTFUART_ENABLED
// -------------------------------------------------------------------

#if 0
// --------------------------------------------------------------
#define assertUART(x) if (!(x)) { __assertUART(__FILE__, __LINE__); }
void __assertUART(const char* file, int line)
{
    printfUART("ASSERT FAILED: file= %s, lineNbr= %i\n", file, line);
    // for some reason, CLR means on
    TOSH_MAKE_RED_LED_OUTPUT();
    TOSH_MAKE_YELLOW_LED_OUTPUT();
    TOSH_MAKE_GREEN_LED_OUTPUT();
    TOSH_CLR_RED_LED_PIN();
    TOSH_CLR_YELLOW_LED_PIN();
    TOSH_CLR_GREEN_LED_PIN();
    exit(1);
}
// --------------------------------------------------------------
#endif

#endif  // PRINTFUART_H
#endif  // PRINTFZ1_H

