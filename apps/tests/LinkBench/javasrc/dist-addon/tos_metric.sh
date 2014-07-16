#!/bin/bash
# TinyOS software metric generator script
# This script's purpose is to run the LinkBench application with
# arbitrary benchmarks, but using always different TinyOS svn revisions.
#

PROGNAME=`basename $0`
PROGVERSION=0.1

# default values
MPLATFORM=iris
TOSSVNDIR=$TINYOS_ROOT_DIR
LINKBDIR=".."
START_DATE=`date +%Y-%m-%d`
STOP_DATE=`date +%Y-%m-%d`
DATE_STEP='1 month'
BENCH_FILE="batchfiles/${PROGNAME%.*}.yml"

LOGFILE=${PROGNAME%.*}.log

SHORTOPTS="hvF:" 
LONGOPTS="help,version,svn:,step:,benchfile:,start:,stop:" 
usage()
{ 
  echo "
  Usage: $PROGNAME [options] [LinkBench root dir]
         
    Executes a TinyOS metric using different SVN revisions and the LinkBench TinyOS application.
    Revisions are going from 'start date' until 'stop date'. Date format is YYYY-MM-DD. Stop date
    is defaulted to the current date.
    
    Step size can be configured using the --step option.
 
    Options: 
       -h|--help        show this output 
       -v|--version     show version information
       -F|--benchfile   the benchmark batch file to use [ default : $BENCH_FILE ]
       --start <date>   set the start date in format: YYYY-MM-DD
       --stop  <date>   set the stop  date in format: YYYY-MM-DD
       --svn   <dir >    set the TinyOS root directory   [ default : $TINYOS_ROOT_DIR ]
       --step  <spec>   set the step size in format : [1-9][0-9]* day|month|year
          examples: 10 day, 2 day, 2 month, 1 year
  " 
}

check_params() {
  echo -e " SVN repository : \033[1m$TOSSVNDIR\033[0m"
  if [[ ! -d $TOSSVNDIR || ! -r $TOSSVNDIR || ! -w $TOSSVNDIR || ! -x $TOSSVNDIR ]]; then
    echo "   '$TOSSVNDIR' is not a good location as SVN root directory!"
    exit 1
  fi

  echo -e " LinkBench dir. : \033[1m$LINKBDIR\033[0m"  
  if [[ ! -e $LINKBDIR/BenchmarkAppC.nc || ! -d $LINKBDIR/javasrc || ! -e $LINKBDIR/javasrc/build.xml ]]; then
    echo "   '$LINKBDIR' does not seem to be the LinkBench application's root directory!"
    exit 1
  fi

  echo -e " Benchmark file : \033[1m$BENCH_FILE\033[0m"  
  if [[ ! -e $BENCH_FILE ]]; then
    echo "   '$BENCH_FILE' does not exist!"
    exit 1
  fi

  check_date $START_DATE
  if [ $? -gt 0 ]; then
    echo "   '$START_DATE' is not a valid date!"
    exit 1
  fi
  
  check_date $STOP_DATE
  if [ $? -gt 0 ]; then
    echo "   '$STOP_DATE' is not a valid date!"
    exit 1
  fi
  
  date1_le_date2 $START_DATE $STOP_DATE
  if [ $? -gt 0 ]; then
    echo "   '$START_DATE' is in the future compared to '$STOP_DATE'!"
    exit 1
  fi
  
  if [ `echo $DATE_STEP | grep -c '[1-9][0-9]* \(day\|month\|year\)'` -eq 0 ]; then
    echo "   '$DATE_STEP' is not a valid time step!"
    exit 1
  else
    DATE_STEP=`echo $DATE_STEP | grep -o '[1-9][0-9]* \(day\|month\|year\)'`;
  fi
  
  # count how many iterations we will have
  STEP_TOTAL=0
  DATE_TMP=$START_DATE
  date1_le_date2 $DATE_TMP $STOP_DATE
  while [ $? -eq 0 ]; do
    ((STEP_TOTAL++))
    DATE_TMP=`date -d "$DATE_TMP +$DATE_STEP" +%Y-%m-%d`
    date1_le_date2 $DATE_TMP $STOP_DATE
  done
  unset DATE_TMP
  
  echo -e " Date  interval : \033[1m$START_DATE\033[0m -> \033[1m$STOP_DATE\033[0m with \033[1m$DATE_STEP\033[0m increment ( total of $STEP_TOTAL step(s) )"
}

# check if valid date
check_date() {
  if [ `echo $1 | grep -E -c '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}'` -eq 0 ]; then
    return 1;
  fi
  declare -i year month day
  eval $(echo $1 | sed 's:\([0-9]*\)-\([0-9]*\)-\([0-9]*\):year=\1 month=\2 day=\3:')
  return `cal $month $year | grep -c -w $day >/dev/null`
}

# check if $1 < $2 chronologically
date1_le_date2() {
  if [[ `echo "$(date -d $1 +%s) <= $(date -d $2 +%s)" | bc` == "1" ]]; then
    return 0
  else
    return 1
  fi
}

check_last() {
  RET=$?
  DOFAIL="no"
  [ "$1" = "--fail" ] && DOFAIL="yes" && shift
  cat $3 >> $LOGFILE
  if [ $RET -eq 0 ]; then
    echo -ne "[\033[1m $1 \033[0m]"
    return 0
  else
    echo -ne "[\033[1m $2 \033[0m]"
    [ $DOFAIL = "yes" ] && return 1
    cat $3
    rm $3
    exit 1
  fi
}

#
# PARSE COMMAND LINE
#
ARGS=$(getopt -s bash --options $SHORTOPTS --longoptions $LONGOPTS --name $PROGNAME -- "$@" ) 
eval set -- "$ARGS"

while true; do
   case $1 in 
      -h|--help) 
         usage; exit 0;; 
      -v|--version) 
         echo "$PROGNAME version $PROGVERSION"; exit 0;;
      -F|--benchfile)
         shift;
         BENCH_FILE=$1;;
      --svn)
         shift; 
         TOSSVNDIR=$1;;
      --step) 
         shift; 
         DATE_STEP=$1;;
      --start)
         shift; 
         START_DATE=$1;;
      --stop)
         shift; 
         STOP_DATE=$1;;                
      --) shift ; break ;;
      *)  shift ; break ;;
   esac 
   shift 
done

# parse mandatory parameters
if [[ $# -gt 0 ]]; then
  LINKBDIR=$1;
fi

# check for the established parameters if they are valid or not
check_params

SVNBIN=/usr/bin/svn
TMP=`tempfile`
trap '{ rm -f "$TMP"; }' EXIT

# make executable the linkbench.sh script
chmod +x linkbench.sh

echo "-------------------------------------------------------------------------------------------"

# while we do not run past the stop date
STEP_CURRENT=0
NEXT_DATE=$START_DATE

rm -f $LOGFILE
while [ $STEP_CURRENT -lt $STEP_TOTAL ]; do
  
  ((STEP_CURRENT++))
  # we can initiate the next svn update, to save as much time as we can.
  START_DATE=$NEXT_DATE
  NEXT_DATE=`date -d "$START_DATE +$DATE_STEP" +%Y-%m-%d`
  
  printf "(%2d/%2d) - %s : " $STEP_CURRENT $STEP_TOTAL $START_DATE | tee -a $LOGFILE
  
  # (1) update the svn repository
  ( cd $TOSSVNDIR; $SVNBIN update -r {$START_DATE} > $TMP 2>&1 )
  check_last "Rev: `tail -1 $TMP | tr -cd '[:digit:]'`" "SVN ERROR" $TMP
  
  # (2) re-make the nesc code
  ( cd $LINKBDIR; ./minstall.sh --compileonly > $TMP 2>&1 )
  check_last --fail "COMPILE OK" "COMPILE ERROR" $TMP || { echo ""; continue; }
  
  # (3) program the motes
  ( cd $LINKBDIR ; ./minstall.sh --progonly > $TMP 2>&1 )
  check_last --fail "PROGRAM OK" "PROGRAM ERROR" $TMP || { echo ""; continue; }
  sleep 2
  
  # (4) run the benchmark
  ./linkbench.sh -F $BENCH_FILE -o result-${START_DATE}.xml > $TMP 2>&1
  check_last "RUN OK" "RUN ERROR" $TMP
  
  sleep 2
  ./linkbench.sh -r > $TMP 2>&1
  check_last "RESET OK" "RESET ERROR" $TMP
  
  # (5) clean
  ( cd $LINKBDIR; make clean 2>&1 | tee -a $LOGFILE > $TMP )
  check_last "CLEAN OK" "CLEAN ERROR" $TMP
  
  echo ""
done
rm $TMP
exit 0
