/* Copyright (c) 2002, 2003, 2004  Eric B. Weddington
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
   * Neither the name of the copyright holders nor the names of
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

#ifndef _AVR_BOOT_H_
#define _AVR_BOOT_H_    1

/** \defgroup avr_boot Bootloader Support Utilities
    \code
    #include <avr/io.h>
    #include <avr/boot.h>
    \endcode

    The macros in this module provide a C language interface to the
    bootloader support functionality of certain AVR processors. These
    macros are designed to work with all sizes of flash memory.

    \note Not all AVR processors provide bootloader support. See your
    processor datasheet to see if it provides bootloader support.

    \todo From email with Marek: On smaller devices (all except ATmega64/128),
    __SPM_REG is in the I/O space, accessible with the shorter "in" and "out"
    instructions - since the boot loader has a limited size, this could be an
    important optimization.

    \par API Usage Example
    The following code shows typical usage of the boot API.

    \code
    #include <avr/interrupt.h>
    #include <avr/pgmspace.h>
    
    #define ADDRESS     0x1C000UL
    
    void boot_test(void)
    {
        unsigned char buffer[8];
    
        cli();
    
        // Erase page.
        boot_page_erase((unsigned long)ADDRESS);
        while(boot_rww_busy())
        {
            boot_rww_enable();
        }
    
        // Write data to buffer a word at a time. Note incrementing address
        // by 2. SPM_PAGESIZE is defined in the microprocessor IO header file.
        for(unsigned long i = ADDRESS; i < ADDRESS + SPM_PAGESIZE; i += 2)
        {
            boot_page_fill(i, (i-ADDRESS) + ((i-ADDRESS+1) << 8));
        }
    
        // Write page.
        boot_page_write((unsigned long)ADDRESS);
        while(boot_rww_busy())
        {
            boot_rww_enable();
        }
    
        sei();
    
        // Read back the values and display.
        // (The show() function is undefined and is used here as an example
        // only.)
        for(unsigned long i = ADDRESS; i < ADDRESS + 256; i++)
        {
            show(utoa(pgm_read_byte(i), buffer, 16));
        }
    
        return;
    }\endcode */

#include <avr/eeprom.h>
#include <avr/io.h>
#include <inttypes.h>
#include <limits.h>

/* Check for SPM Control Register in processor. */
#if defined (SPMCSR)
#  define __SPM_REG    SPMCSR
#elif defined (SPMCR)
#  define __SPM_REG    SPMCR
#else
#  error AVR processor does not provide bootloader support!
#endif

/** \ingroup avr_boot
    \def BOOTLOADER_SECTION

    Used to declare a function or variable to be placed into a
    new section called .bootloader. This section and its contents
    can then be relocated to any address (such as the bootloader
    NRWW area) at link-time. */

#define BOOTLOADER_SECTION    __attribute__ ((section (".bootloader")))

/* Create common bit definitions. */
#ifdef ASB
#define __COMMON_ASB    ASB
#else
#define __COMMON_ASB    RWWSB
#endif

#ifdef ASRE
#define __COMMON_ASRE   ASRE
#else
#define __COMMON_ASRE   RWWSRE
#endif

/* Define the bit positions of the Boot Lock Bits. */

#define BLB12           5
#define BLB11           4
#define BLB02           3
#define BLB01           2

/** \ingroup avr_boot
    \def boot_spm_interrupt_enable()
    Enable the SPM interrupt. */

#define boot_spm_interrupt_enable()   (__SPM_REG |= (uint8_t)_BV(SPMIE))

/** \ingroup avr_boot
    \def boot_spm_interrupt_disable()
    Disable the SPM interrupt. */

#define boot_spm_interrupt_disable()  (__SPM_REG &= (uint8_t)~_BV(SPMIE))

/** \ingroup avr_boot
    \def boot_is_spm_interrupt()
    Check if the SPM interrupt is enabled. */

#define boot_is_spm_interrupt()       (__SPM_REG & (uint8_t)_BV(SPMIE))

/** \ingroup avr_boot
    \def boot_rww_busy()
    Check if the RWW section is busy. */

#define boot_rww_busy()          (__SPM_REG & (uint8_t)_BV(__COMMON_ASB))

/** \ingroup avr_boot
    \def boot_spm_busy()
    Check if the SPM instruction is busy. */

#define boot_spm_busy()               (__SPM_REG & (uint8_t)_BV(SPMEN))

/** \ingroup avr_boot
    \def boot_spm_busy_wait()
    Wait while the SPM instruction is busy. */

#define boot_spm_busy_wait()          do{}while(boot_spm_busy())

#define __BOOT_PAGE_ERASE         (_BV(SPMEN) | _BV(PGERS))
#define __BOOT_PAGE_WRITE         (_BV(SPMEN) | _BV(PGWRT))
#define __BOOT_PAGE_FILL          _BV(SPMEN)
#define __BOOT_RWW_ENABLE         (_BV(SPMEN) | _BV(__COMMON_ASRE))
#define __BOOT_LOCK_BITS_SET      (_BV(SPMEN) | _BV(BLBSET))

#define __BOOT_LOCK_BITS_MASK     (_BV(BLB01) | _BV(BLB02) \
                                   | _BV(BLB11) | _BV(BLB12))

#define eeprom_busy_wait() do {} while (!eeprom_is_ready())

#define __boot_page_fill_normal(address, data)   \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw  r0, %3\n\t"                       \
        "movw r30, %2\n\t"                       \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        "clr  r1\n\t"                            \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_PAGE_FILL),       \
          "r" ((uint16_t)address),               \
          "r" ((uint16_t)data)                   \
        : "r0", "r30", "r31"                     \
    );                                           \
})

#define __boot_page_fill_alternate(address, data)\
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw  r0, %3\n\t"                       \
        "movw r30, %2\n\t"                       \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        ".word 0xffff\n\t"                       \
        "nop\n\t"                                \
        "clr  r1\n\t"                            \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_PAGE_FILL),       \
          "r" ((uint16_t)address),               \
          "r" ((uint16_t)data)                   \
        : "r0", "r30", "r31"                     \
    );                                           \
})

#define __boot_page_fill_extended(address, data) \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw  r0, %4\n\t"                       \
        "movw r30, %A3\n\t"                      \
        "sts %1, %C3\n\t"                        \
        "sts %0, %2\n\t"                         \
        "spm\n\t"                                \
        "clr  r1\n\t"                            \
        : "=m" (__SPM_REG),                      \
          "=m" (RAMPZ)                           \
        : "r" ((uint8_t)__BOOT_PAGE_FILL),       \
          "r" ((uint32_t)address),               \
          "r" ((uint16_t)data)                   \
        : "r0", "r30", "r31"                     \
    );                                           \
})

#define __boot_page_erase_normal(address)        \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw r30, %2\n\t"                       \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_PAGE_ERASE),      \
          "r" ((uint16_t)address)                \
        : "r30", "r31"                           \
    );                                           \
})

#define __boot_page_erase_alternate(address)     \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw r30, %2\n\t"                       \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        ".word 0xffff\n\t"                       \
        "nop\n\t"                                \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_PAGE_ERASE),      \
          "r" ((uint16_t)address)                \
        : "r30", "r31"                           \
    );                                           \
})

#define __boot_page_erase_extended(address)      \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw r30, %A3\n\t"                      \
        "sts  %1, %C3\n\t"                       \
        "sts %0, %2\n\t"                         \
        "spm\n\t"                                \
        : "=m" (__SPM_REG),                      \
          "=m" (RAMPZ)                           \
        : "r" ((uint8_t)__BOOT_PAGE_ERASE),      \
          "r" ((uint32_t)address)                \
        : "r30", "r31"                           \
    );                                           \
})

#define __boot_page_write_normal(address)        \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw r30, %2\n\t"                       \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_PAGE_WRITE),      \
          "r" ((uint16_t)address)                \
        : "r30", "r31"                           \
    );                                           \
})

#define __boot_page_write_alternate(address)     \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw r30, %2\n\t"                       \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        ".word 0xffff\n\t"                       \
        "nop\n\t"                                \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_PAGE_WRITE),      \
          "r" ((uint16_t)address)                \
        : "r30", "r31"                           \
    );                                           \
})

#define __boot_page_write_extended(address)      \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "movw r30, %A3\n\t"                      \
        "sts %1, %C3\n\t"                        \
        "sts %0, %2\n\t"                         \
        "spm\n\t"                                \
        : "=m" (__SPM_REG),                      \
          "=m" (RAMPZ)                           \
        : "r" ((uint8_t)__BOOT_PAGE_WRITE),      \
          "r" ((uint32_t)address)                \
        : "r30", "r31"                           \
    );                                           \
})

#define __boot_rww_enable()                      \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_RWW_ENABLE)       \
    );                                           \
})

#define __boot_rww_enable_alternate()            \
({                                               \
    boot_spm_busy_wait();                        \
    eeprom_busy_wait();                          \
    __asm__ __volatile__                         \
    (                                            \
        "sts %0, %1\n\t"                         \
        "spm\n\t"                                \
        ".word 0xffff\n\t"                       \
        "nop\n\t"                                \
        : "=m" (__SPM_REG)                       \
        : "r" ((uint8_t)__BOOT_RWW_ENABLE)       \
    );                                           \
})

#define __boot_lock_bits_set(lock_bits)                    \
({                                                         \
    uint8_t value = (uint8_t)(lock_bits | __BOOT_LOCK_BITS_MASK); \
    boot_spm_busy_wait();                                  \
    eeprom_busy_wait();                                    \
    __asm__ __volatile__                                   \
    (                                                      \
        "ldi r30, 1\n\t"                                   \
        "ldi r31, 0\n\t"                                   \
        "mov r0, %2\n\t"                                   \
        "sts %0, %1\n\t"                                   \
        "spm\n\t"                                          \
        : "=m" (__SPM_REG)                                 \
        : "r" ((uint8_t)__BOOT_LOCK_BITS_SET),             \
          "r" (value)                                      \
        : "r0", "r30", "r31"                               \
    );                                                     \
})

#define __boot_lock_bits_set_alternate(lock_bits)          \
({                                                         \
    uint8_t value = (uint8_t)(lock_bits | __BOOT_LOCK_BITS_MASK); \
    boot_spm_busy_wait();                                  \
    eeprom_busy_wait();                                    \
    __asm__ __volatile__                                   \
    (                                                      \
        "ldi r30, 1\n\t"                                   \
        "ldi r31, 0\n\t"                                   \
        "mov r0, %2\n\t"                                   \
        "sts %0, %1\n\t"                                   \
        "spm\n\t"                                          \
        ".word 0xffff\n\t"                                 \
        "nop\n\t"                                          \
        : "=m" (__SPM_REG)                                 \
        : "r" ((uint8_t)__BOOT_LOCK_BITS_SET),       \
          "r" (value)                                      \
        : "r0", "r30", "r31"                               \
    );                                                     \
})

/** \ingroup avr_boot
    \def boot_page_fill(address, data)

    Fill the bootloader temporary page buffer for flash 
    address with data word. 

    \note The address is a byte address. The data is a word. The AVR 
    writes data to the buffer a word at a time, but addresses the buffer
    per byte! So, increment your address by 2 between calls, and send 2
    data bytes in a word format! The LSB of the data is written to the lower 
    address; the MSB of the data is written to the higher address.*/

/** \ingroup avr_boot
    \def boot_page_erase(address)

    Erase the flash page that contains address.

    \note address is a byte address in flash, not a word address. */

/** \ingroup avr_boot
    \def boot_page_write(address)

    Write the bootloader temporary page buffer 
    to flash page that contains address.
    
    \note address is a byte address in flash, not a word address. */

/** \ingroup avr_boot
    \def boot_rww_enable()

    Enable the Read-While-Write memory section. */

/** \ingroup avr_boot
    \def boot_lock_bits_set(lock_bits)

    Set the bootloader lock bits. */

/* Normal versions of the macros use 16-bit addresses.
   Extended versions of the macros use 32-bit addresses.
   Alternate versions of the macros use 16-bit addresses and require special
   instruction sequences after LPM.

   FLASHEND is defined in the ioXXXX.h file.
   USHRT_MAX is defined in <limits.h>. */ 

#if defined(__AVR_ATmega161__) || defined(__AVR_ATmega163__) \
    || defined(__AVR_ATmega323__)

/* Alternate: ATmega161/163/323 and 16 bit address */
#define boot_page_fill(address, data) __boot_page_fill_alternate(address, data)
#define boot_page_erase(address)      __boot_page_erase_alternate(address)
#define boot_page_write(address)      __boot_page_write_alternate(address)
#define boot_rww_enable()             __boot_rww_enable_alternate()
#define boot_lock_bits_set(lock_bits) __boot_lock_bits_set_alternate(lock_bits)

#elif (FLASHEND > USHRT_MAX) && !defined(__USING_MINT8)

/* Extended: >16 bit address */
#define boot_page_fill(address, data) __boot_page_fill_extended(address, data)
#define boot_page_erase(address)      __boot_page_erase_extended(address)
#define boot_page_write(address)      __boot_page_write_extended(address)
#define boot_rww_enable()             __boot_rww_enable()
#define boot_lock_bits_set(lock_bits) __boot_lock_bits_set(lock_bits)

#else

/* Normal: 16 bit address */
#define boot_page_fill(address, data) __boot_page_fill_normal(address, data)
#define boot_page_erase(address)      __boot_page_erase_normal(address)
#define boot_page_write(address)      __boot_page_write_normal(address)
#define boot_rww_enable()             __boot_rww_enable()
#define boot_lock_bits_set(lock_bits) __boot_lock_bits_set(lock_bits)

#endif

#endif /* _AVR_BOOT_H_ */
