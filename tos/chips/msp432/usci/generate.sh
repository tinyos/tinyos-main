#!/bin/sh
#
# Given implementations for USCI_A0 and USCI_B0, generate equivalent
# configurations for the higher-numbered module instances.
#
# Much of the USCI implementation is identical except for varying
# based on the instance number of the module to which a component
# belongs.  To avoid implementation divergence, we maintain and evolve
# only one of each type of component, and generate the remainder from
# that template.
#
# @author Peter A. Bigot <pab@peoplepowerco.com>
# @author Eric B. Decker <cire831@gmail.com>
#
# UART is implemented in USCI_A modules
# I2C  is implemented in USCI_B modules
# SPI  is implemented in USCI_A and USCI_B modules
#
# List of tags for USCI_Ax modules.  A0 is the master for A
# modules and Uart.
#
# The main Usci instantiators for the Usci are Msp432Usci<port>P.
# Because of differences in the h/w we need to pass in information
# that tells which structure to use.  The master for this is
# Msp432UsciZ9P.nc.  The type is Z9_TYPE.
#
# Masters are:
#
# HplMsp432UsciIntA0P.nc        interrupt master
# Msp432UsciZ9P.nc              Usci instantiator
# Msp432UartA0{C,P}.nc          Uart master
# Msp432SpiB0{C,P}.nc           Spi master
# Msp432I2CB0{C,P}.nc           I2C master
#

A_MODULES='A0 A1 A2 A3'

# List of tags for USCI_Ax modules.  B0 is the master for B
# modules and Spi (B and A) and I2C modules.

B_MODULES='B0 B1 B2 B3'

# Initialize a file that will contain a list of all generated files,
# so we can remove them during basic maintenance.  Their presence
# clutters the directory and makes it difficult to see what's really
# important.

rm -f generated.lst

clone_module () {
  source="$1" ; shift
  target="$1" ; shift
  basis="$1" ; shift
  clone="$1" ; shift
  type="$1"; shift
  echo clone: ${source} "->" ${target}    ${basis}/${clone} \(${type}\)
  ( cat<<EOText
/*
 * DO NOT MODIFY: This file cloned from ${source} for ${clone}
*/
EOText
    cat ${source} \
      | sed -e "s@Z9_TYPE@${type}@g" \
      | sed -e "s@${basis}@${clone}@g"
  ) > ${target}
  echo ${target} >> generated.lst
}

# The interrupt modules use A0 as master
for m in ${A_MODULES} ${B_MODULES} ; do
  if [ A0 = "${m}" ] ; then
    continue
  fi
  clone_module HplMsp432UsciIntA0P.nc "HplMsp432UsciInt${m}P.nc" A0 "${m}" 2
done

# The Msp432Usci<Port>P files are generated from the master Msp432UsciZ9P.nc
# they need to also have the Type of the port modified.
for m in ${A_MODULES} ; do
  clone_module Msp432UsciZ9P.nc "Msp432Usci${m}P.nc" Z9 "${m}" 0
done
for m in ${B_MODULES} ; do
  clone_module Msp432UsciZ9P.nc "Msp432Usci${m}P.nc" Z9 "${m}" 1
done


# Clone the mode-specific configurations for a given module type
clone_mode_modules () {
  mode="${1}" ; shift
  basis="${1}" ; shift
  echo block: "${mode}${basis}"
  for source in Msp432Usci${mode}${basis}?.nc ; do
    for clone in "${@}" ; do
      target=`echo ${source} | sed -e "s@${basis}@${clone}@g"`
      clone_module ${source} ${target} ${basis} ${clone} 2
    done
  done
}

# Clone the mode-specific configurations
clone_mode_modules Uart ${A_MODULES}
clone_mode_modules Spi ${B_MODULES} ${A_MODULES}
clone_mode_modules I2C ${B_MODULES}
