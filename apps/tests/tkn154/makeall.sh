#!/bin/bash
# compile/clean all test applications
PLATFORM=$1
OPTIONS=
STARTDIR=`pwd`
MAKEFILES=`find . -name Makefile`

if [ $# == 0 ];
then
  echo "Usage: $0 <platform|clean>"
  exit
fi

for m in $MAKEFILES
do
  cd ${m%Makefile}
  if [ "x$1" == xclean ];
  then
    make clean
  else
    make $PLATFORM $OPTIONS;
  fi
  cd $STARTDIR
done
exit

