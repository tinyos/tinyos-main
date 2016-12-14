#!/bin/sh
#
# MuxAlarm has a variant matrix that include Precision and Size
# Precision := [Second | Milli | 32khz] and Size := [16 | 32].
#
# Starting with a master, MuxAlarmMilli32C, generate all the
# variants using simple string substitution.
#
# @author Peter A. Bigot <pab@peoplepowerco.com>

# List of precision tags
PREC_TAGS="Second Milli 32khz"
# List of size tags
SIZE_TAGS="16 32"

# Initialize a file that will contain a list of all generated files,
# so we can remove them during basic maintenance.  Their presence
# clutters the directory and makes it difficult to see what's really
# important.
rm -f generated.lst

BASIS_PREC=Milli
BASIS_SIZE=32

clone_module () {
  source="$1" ; shift
  prec="$1" ; shift
  size="$1" ; shift
  sed_args="-e s@${BASIS_SIZE}@${size}@g -e s@${BASIS_PREC}@${prec}@g"
  target=$(echo ${source} | sed ${sed_args})
  ( cat<<EOText
/* DO NOT MODIFY
 * This file cloned from ${source} for PRECISION_TAG=${prec} and SIZE_TYPE=${size} */
EOText
    cat ${source} \
      | sed ${sed_args}
  ) > ${target}
  echo ${target} >> generated.lst
}

for p in ${PREC_TAGS} ; do
  for s in ${SIZE_TAGS} ; do
    if [ "${BASIS_PREC}" = "${p}" -a "${BASIS_SIZE}" = "${s}" ] ; then
      continue
    fi
    clone_module MuxAlarm${BASIS_PREC}${BASIS_SIZE}C.nc ${p} ${s}
    clone_module MuxAlarm${BASIS_PREC}${BASIS_SIZE}C_.nc ${p} ${s}
  done
done
