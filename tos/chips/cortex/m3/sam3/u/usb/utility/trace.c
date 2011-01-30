/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 * ----------------------------------------------------------------------------
 */


//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------

#include "trace.h"

//------------------------------------------------------------------------------
//         Internal variables
//------------------------------------------------------------------------------

/// Trace level can be set at applet initialization
#if !defined(NOTRACE) && (DYN_TRACES == 1)
    unsigned int traceLevel = TRACE_LEVEL;
#endif
  
#ifndef NOFPUT
#include <stdio.h>
#include <stdarg.h>

//------------------------------------------------------------------------------
/// \exclude
/// Implementation of fputc using the DBGU as the standard output. Required
/// for printf().
/// \param c  Character to write.
/// \param pStream  Output stream.
/// \param The character written if successful, or -1 if the output stream is
/// not stdout or stderr.
//------------------------------------------------------------------------------
signed int fputc(signed int c, FILE *pStream)
{
    if ((pStream == stdout) || (pStream == stderr)) {

        TRACE_PutChar(c);
        return c;
    }
    else {

        return EOF;
    }
}

//------------------------------------------------------------------------------
/// \exclude
/// Implementation of fputs using the DBGU as the standard output. Required
/// for printf(). Does NOT currently use the PDC.
/// \param pStr  String to write.
/// \param pStream  Output stream.
/// \return Number of characters written if successful, or -1 if the output
/// stream is not stdout or stderr.
//------------------------------------------------------------------------------
signed int fputs(const char *pStr, FILE *pStream)
{
    signed int num = 0;

    while (*pStr != 0) {

        if (fputc(*pStr, pStream) == -1) {

            return -1;
        }
        num++;
        pStr++;
    }

    return num;
}

#undef putchar

//------------------------------------------------------------------------------
/// \exclude
/// Outputs a character on the DBGU.
/// \param c  Character to output.
/// \return The character that was output.
//------------------------------------------------------------------------------
signed int putchar(signed int c)
{
    return fputc(c, stdout);
}

#endif //#ifndef NOFPUT

//------------------------------------------------------------------------------
//         Local Functions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// Print char if printable. If not print a point
/// \param c char to
//------------------------------------------------------------------------------
static void PrintChar(unsigned char c)
{
    if( (/*c >= 0x00 &&*/ c <= 0x1F) ||
        (c >= 0xB0 && c <= 0xDF) ) {

       printf(".");
    }
    else {

       printf("%c", c);
    }
}

//------------------------------------------------------------------------------
//         Global Functions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// Displays the content of the given frame on the Trace interface.
/// \param pBuffer  Pointer to the frame to dump.
/// \param size  Buffer size in bytes.
//------------------------------------------------------------------------------
void TRACE_DumpFrame(unsigned char *pFrame, unsigned int size)
{
    unsigned int i;

    for (i=0; i < size; i++) {
        printf("%02X ", pFrame[i]);
    }

    printf("\n\r");
}

//------------------------------------------------------------------------------
/// Displays the content of the given buffer on the Trace interface.
/// \param pBuffer  Pointer to the buffer to dump.
/// \param size     Buffer size in bytes.
/// \param address  Start address to display
//------------------------------------------------------------------------------
void TRACE_DumpMemory(
    unsigned char *pBuffer,
    unsigned int size,
    unsigned int address
    )
{
    unsigned int i, j;
    unsigned int lastLineStart;
    unsigned char* pTmp;

    for (i=0; i < (size / 16); i++) {

        printf("0x%08X: ", address + (i*16));
        pTmp = (unsigned char*)&pBuffer[i*16];
        for (j=0; j < 4; j++) {
            printf("%02X%02X%02X%02X ", pTmp[0],pTmp[1],pTmp[2],pTmp[3]);
            pTmp += 4;
        }

        pTmp = (unsigned char*)&pBuffer[i*16];
        for (j=0; j < 16; j++) {
            PrintChar(*pTmp++);
        }

        printf("\n\r");
    }

    if( (size%16) != 0) {
        lastLineStart = size - (size%16);
        printf("0x%08X: ", address + lastLineStart);

        for (j= lastLineStart; j < lastLineStart+16; j++) {

            if( (j!=lastLineStart) && (j%4 == 0) ) {
                printf(" ");
            }
            if(j<size) {
                printf("%02X", pBuffer[j]);
            }
            else {
                printf("  ");
            }
        }

        printf(" ");
        for (j= lastLineStart; j <size; j++) {
            PrintChar(pBuffer[j]);
        }

        printf("\n\r");
    }
}
    
//------------------------------------------------------------------------------
/// Reads an integer
//------------------------------------------------------------------------------
unsigned char TRACE_GetInteger(unsigned int *pValue)
{
    unsigned char key;
    unsigned char nbNb = 0;
    unsigned int value = 0;
    while(1) {
        key = TRACE_GetChar();
        TRACE_PutChar(key);
        if(key >= '0' &&  key <= '9' ) {
            value = (value * 10) + (key - '0');
            nbNb++;
        }
        else if(key == 0x0D || key == ' ') {
            if(nbNb == 0) {
                printf("\n\rWrite a number and press ENTER or SPACE!\n\r");       
                return 0; 
            } else {
                printf("\n\r"); 
                *pValue = value;
                return 1;
            }
        } else {
            printf("\n\r'%c' not a number!\n\r", key);
            return 0;  
        }
    }
}

//------------------------------------------------------------------------------
/// Reads an integer and check the value
//------------------------------------------------------------------------------
unsigned char TRACE_GetIntegerMinMax(
    unsigned int *pValue, 
    unsigned int min, 
    unsigned int max
    )
{
    unsigned int value = 0;

    if( TRACE_GetInteger(&value) == 0) {
        return 0;
    }
    
    if(value < min || value > max) {
        printf("\n\rThe number have to be between %d and %d\n\r", min, max);
        return 0; 
    }

    printf("\n\r"); 
    *pValue = value;
    return 1;
}

//------------------------------------------------------------------------------
/// Reads an hexadecimal number
//------------------------------------------------------------------------------
unsigned char TRACE_GetHexa32(unsigned int *pValue)
{
    unsigned char key;
    unsigned int i = 0;
    unsigned int value = 0;
    for(i = 0; i < 8; i++) {
        key = TRACE_GetChar();
        TRACE_PutChar(key);
        if(key >= '0' &&  key <= '9' ) {
            value = (value * 16) + (key - '0');
        }
        else if(key >= 'A' &&  key <= 'F' ) {
            value = (value * 16) + (key - 'A' + 10) ;
        }
        else if(key >= 'a' &&  key <= 'f' ) {
            value = (value * 16) + (key - 'a' + 10) ;
        }        
        else {
            printf("\n\rIt is not a hexa character!\n\r");       
            return 0; 
        }
    }

    printf("\n\r");    
    *pValue = value;     
    return 1;
}

