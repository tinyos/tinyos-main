This directory contains support for the TI msp432 eUSCI

TI has a multipurpose serial device called the Universal Serial
Communications Interface.  There are many different flavors that all
behave differently.  Further, they are split into A  and B modules and
have to be utilized appropriately.  The A modules can be programed to
be a UART, SPI, or IRDA controller.  B modules can be SPI or I2C.

The MSP432 implements the eUSCI which is essentially the same as the
MSP430 x5 family USCI.  There are some enhancements hence the "e"  in
its name.

The underlying h/w a USCI block
There is a generic concept of a USCI module.  Different chip families
support different types of module; these are denoted by a suffix letter
(e.g., USCI_Ax or USCI_Bx).  The types of module differ by the functional
modes they support: USCI_Ax supports UART and SPI, while USCI_Bx supports
SPI and I2C.  There can be any number of instances of a given module type on
a given chip; the MSP430x54xx chips support up to four each of USCI_Ax and
USCI_Bx.

The driver for the refactoring was elimination of duplicated code.
Since NesC does not support the level of genericity required to do this
within the language, one characteristic instance of each capability is
maintained, and the others are generated from it using the generate.sh
script.

The list of files that are derived are maintained in the file generated.lst,
which itself is generated as a side effect of running generate.sh.  When
attempting to understand the system and do basic maintainance, it may be
worth running:

   cat generated.lst | xargs rm

to clear the clutter out of the way.

When you are happy with the changes to the master files, regenerate all
the clones by simply running generate.sh (./generate.sh to a shell).


Common USCI Support
-------------------

The interface HplMsp430Usci supports the common control registers present
in both A and B modules.  A corresponding HplMsp430UsciP provides a
generic implementation that uses a pointer to the modules registers.  These
registers are referenced through this pointer using a structure definition.
Unfortunatly, the structures for the A parts and B parts are different
enough that we need to know this.

HplMsp430UsciInt.nc specifies the USCI interrupts interface for
the MSP432 USCI.  Because interrupt handlers cannot be defined in generic
modules, HplMsp430UsciA0P.nc is a maintained non-generic module that
defines the interrupt vector.

Msp430UsciZ9P.nc is the maintained configuration implementation for
top-level USCI instances, linking the instantiated generic USCI
implementation with proper the non-generic interrupt implementation.

Uart Mode Support
-----------------

Msp430UsciP.nc is a maintained generic module that supports standard UART
interfaces, relative to an externally provided USCI interface.

Msp430UsciUartA0P.nc is the maintained non-generic configuration for the UART
capability on a specific module instance.  Platform-specific configurations
should wire up the appropriate chip pins for URXD and UTXD.

Msp430UsciUartA0C.nc is the maintained configuration that is used by
applications.

SPI Mode Support
----------------

Msp430UsciSpiP.nc is a maintained generic module that supports
parameterized versions of the standard SPI interfaces, relative to an
externally provided USCI interface.

For historical reasons, the maintained implementation for SPI is in files
Msp430UsciSpiB0P.nc and Msp430UsciSpiB0C.nc.  Platform-specific
configurations should wire the appropriate chip pins to Msp430UsciSpiB0P.

I2C Mode Support
----------------

A series of I2C drivers were written by Doug Carlson and Marcus Chang
(John Hopkins) for both the x2 and x5 processors that implements a
multi-master I2C implementation.  These implementations came from the
breakfast fork at John Hopkins and were brought in as x2xxx/usci-bf
and x5xxx/usci-bf.


These drivers were fleshed out and verified using a logic analyser.
A single master optimization was also added.

This forms the i2c portion of the x5xxx/usci-v2 implementation.  These
have been ported to the msp432.



Notes:

When setting the address of the slave device remember you only need the 7 bits, most
devices datasheets show the address in a 8bit format, e.g 24lc1025 address is 0xA0,
this turns into 0x50, the 7 msb's right shifted one, the read/right bit is added by
the I2C h/w when the transaction is started.  The I2C address registers assume the
right shifted (actual address).

When writing to a device multiple times, check the data sheet for write times, you
need to give the device time to commit before you write again else the i2c access
function will FAIL.  This of course depends on the device.  This failure may or may
not be detected (most likely not) by the local to the cpu USCI h/w.  It depends on
the chip that is being interfaced to via the I2C bus.
