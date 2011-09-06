#!/bin/bash

PROGNAME=${0##*/} 
LOGFILE=${0%.*}.log

SHORTOPTS="hr:o:" 
LONGOPTS="help"

# default values
RESULT_NAME="R"
OUTPUT="results.m"

usage()
{ 
  echo "
  Usage: $PROGNAME [options] < XML file(s) >
    Creates statistics based on XML files. Output is a MATLAB data script. 
    Options: 
       -h               display this help message
       -r <name>        set the output MATLAB variable name
       -o <output file> set the output file name
  " 
}

#
# PARSE COMMAND LINE
# ##################################################
ARGS=$(getopt -s bash --options $SHORTOPTS --longoptions $LONGOPTS --name $PROGNAME -- "$@" ) 
eval set -- "$ARGS"

while true; do
   case $1 in 
      -h|--help) 
          usage; exit 0;; 
      -r) shift;
          RESULT_NAME=$1;;
      -o) shift;
          OUTPUT=$1;;          
      *)  shift ; break;;
   esac
   shift
done

#
# HANDLE ERRORS
# ##################################################
if [ $# -eq 0 ]; then
  echo "No XML files specified! See help (-h)!"
  exit 1
fi

rm -f $OUTPUT

# Make statistics for all files separately
SVN=1;
for f in $@; do  
  if [[ ! -e $f || ! -f $f || ! -r $f ]]; then
    echo "$f does not exist, is not a file, or not readable!"
    exit 1
  fi
  
  # get the list of available benchmarks in the file
  BENCHS=$(grep benchidx $f | tr -cd '[0-9]\n' | sort -n | uniq)
  echo -n "Processing $f ... "
  for bidx in $BENCHS; do
    echo -n "$bidx "
    if [ $# -gt 1 ]; then
      gawk -f mstats.awk benchmark=$bidx svn=$SVN $f | sed "s:RES:${RESULT_NAME}_$bidx:g" >> $OUTPUT
      SVN=$(($SVN+1))
    else
      gawk -f mstats.awk benchmark=$bidx $f | sed "s:RES:${RESULT_NAME}_$bidx:g" >> $OUTPUT
    fi
  done
  echo "done"
done
