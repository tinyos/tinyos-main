/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Header definition for the Nested Vector Interrupt Controller.
 *
 * @author Thomas Schmid
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

#ifndef NVICHARDWARE_H
#define NVICHARDWARE_H

#define __NVIC_PRIO_BITS    4               /*!< standard definition for NVIC Priority Bits */

#define NVIC_AIRCR_VECTKEY    (0x5FA << 16)   /*!< AIRCR Key for write access   */

/**
 *  IO definitions
 * 
 * define access restrictions to peripheral registers
 **/

#define     __I     volatile const            /*!< defines 'read only' permissions      */
#define     __O     volatile                  /*!< defines 'write only' permissions     */
#define     __IO    volatile                  /*!< defines 'read / write' permissions   */


/* memory mapping struct for Nested Vectored Interrupt Controller (NVIC) */
typedef struct
{
  volatile uint32_t iser0;              // Interrupt Set Enable
           uint32_t reserved[31];
  volatile uint32_t icer0;              // Interrupt Clear-enable
           uint32_t reserved1[31];
  volatile uint32_t ispr0;              // Interrupt Set-pending
           uint32_t reserved2[31];
  volatile uint32_t icpr0;              // Interrupt Clear-pending
           uint32_t reserved3[31];
  volatile uint32_t iabr0;              // Interrupt Active Bit
           uint32_t reserved4[63];
  volatile uint8_t  ip[32];             // Interrupt Priority Registers
           uint32_t reserved5[696];
  volatile uint32_t stir;               // Software Trigger Interrupt
}  nvic_t;

typedef union
{
	uint32_t flat;
	struct
	{
		uint8_t		memfaultact:	1;
		uint8_t		busfaultact:	1;
		uint8_t		reserved0:		1;
		uint8_t		usgfaultact:	1;
		uint8_t		reserved1:		3;
		uint8_t		svcallact:		1;
		uint8_t		monitoract:		1;
		uint8_t		reserved2:		1;
		uint8_t		pendsvact:		1;
		uint8_t		systickact:		1;
		uint8_t		usgfaultpended:	1;
		uint8_t		memfaultpended:	1;
		uint8_t		busfaultpended:	1;
		uint8_t		svcallpended:	1;
		uint8_t		memfaultena:	1;
		uint8_t		busfaultena:	1;
		uint8_t		usgfaultena:	1;
		uint16_t	reserved3:	13;
	} __attribute__((__packed__)) bits;
} nvic_shcsr_t;

typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t reserved0        : 1;
        uint32_t sleeonexit       : 1;
        uint32_t sleepdeep        : 1;
        uint32_t reserved1        : 1;
        uint32_t sevonpend        : 1;
        uint32_t reserved2        : 27;
    } __attribute__((__packed__)) bits;
} scr_t;

/* memory mapping struct for System Control Block */
typedef struct
{
    __I  uint32_t CPUID;                        /*!< CPU ID Base Register                                     */
    __IO uint32_t ICSR;                         /*!< Interrupt Control State Register                         */
    __IO uint32_t VTOR;                         /*!< Vector Table Offset Register                             */
    __IO uint32_t AIRCR;                        /*!< Application Interrupt / Reset Control Register           */
    __IO scr_t scr;                             /*!< System Control Register                                  */
    __IO uint32_t CCR;                          /*!< Configuration Control Register                           */
    __IO uint8_t  SHP[12];                      /*!< System Handlers Priority Registers (4-7, 8-11, 12-15)    */
    __IO nvic_shcsr_t SHCSR;                    /*!< System Handler Control and State Register                */
    __IO uint32_t CFSR;                         /*!< Configurable Fault Status Register                       */
    __IO uint32_t HFSR;                         /*!< Hard Fault Status Register                               */
    __IO uint32_t DFSR;                         /*!< Debug Fault Status Register                              */
    __IO uint32_t MMFAR;                        /*!< Mem Manage Address Register                              */
    __IO uint32_t BFAR;                         /*!< Bus Fault Address Register                               */
    __IO uint32_t AFSR;                         /*!< Auxiliary Fault Status Register                          */
    __I  uint32_t PFR[2];                       /*!< Processor Feature Register                               */
    __I  uint32_t DFR;                          /*!< Debug Feature Register                                   */
    __I  uint32_t ADR;                          /*!< Auxiliary Feature Register                               */
    __I  uint32_t MMFR[4];                      /*!< Memory Model Feature Register                            */
    __I  uint32_t ISAR[5];                      /*!< ISA Feature Register                                     */
} scb_t;


/* Memory mapping of Cortex-M3 Hardware */
volatile nvic_t* NVIC = (volatile nvic_t *) 0xE000E100; // NVIC Base Address

#define SCS_BASE            (0xE000E000)                  /*!< System Control Space Base Address    */
#define SCB_BASE            (SCS_BASE +  0x0D00)          /*!< System Control Block Base Address    */

#define SCB                 ((scb_t*)   SCB_BASE)         /*!< SCB configuration struct             */


#endif // SAM3UNVICHARDWARE_H
