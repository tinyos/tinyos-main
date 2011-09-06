#!/bin/bash
# Install the desired nesC code to currently connected motes. Automatic mote
# detection works only with telosa,telosb, and iris motes (but can be easily extended).
#

PROGNAME=${0##*/} 

# default values
START_ID=1
VERBOSE=yes
PROGONLY=no
COMPILEONLY=no
IGNOREUSB=0

LOGFILE=${0%.*}.log

SHORTOPTS="hqi:" 
LONGOPTS="help,quiet,startid:,ignoreusb:,progonly,compileonly"
usage()
{ 
  echo "
  Usage: $PROGNAME [options] [ platform ]
         
    Compiles TinyOS code and programs multiple motes in parallel. Note that
    by default, mote on /dev/ttyUSB0 is ignored (used to be a BaseStation).
 
    Options: 
       -h|--help            show this output 
       -q|--quiet           stay quiet
       --startid     <num>  start the TOS_NODE_ID count from 'num' [ default : $START_ID ]
       -i|--ignoreusb <X>   ignore the mote on port /dev/ttyUSBX   [ default : $IGNOREUSB ]
       --progonly           do not compile, only program
       --compileonly        do not program, only compile
  " 
}

array_find() {
  key=$1; shift
  for i; do [ "$i" = $key ] && return 0; done; return 1;
}

# detect mote USB devices
# tested for telosa/telosb/iris motes
detect_motes() {
  TMP=`tempfile`
  (
    for udi in `hal-find-by-capability --capability serial | sort` 
    do 
      parent=`hal-get-property --udi ${udi} --key "info.parent"`
      grandpa=`hal-get-property --udi ${parent} --key "info.parent"`

      serial=`hal-get-property --udi ${grandpa} --key "usb_device.serial"`
      vendor=`hal-get-property --udi ${parent} --key "usb.vendor_id"`
      product=`hal-get-property --udi ${parent} --key "usb.product_id"`
      device=`hal-get-property --udi ${udi} --key "linux.device_file"`
      desc=`hal-get-property --udi ${parent} --key "usb.interface.description"`
    
      echo $serial $vendor $product $device $desc >> $TMP;
      [ $VERBOSE != "no" ] && echo "Detected : $serial $vendor $product $device $desc"
    done
  )
  if [[ `cat $TMP | wc -l` == "0" ]]; then
    [ $VERBOSE != "no" ] && echo "No devices found."
    rm $TMP
    return 1
  fi

  TELOS_B=`sort $TMP | grep '1027 24577.*Rev.B' | awk '{print $4}'`
  TELOS_A=`sort $TMP | grep '1027 24577.*Rev A' | awk '{print $4}'`
  MIB520=`sort $TMP | grep '1027 24592' | awk '{print $4}' | sed -n '1~2p'`
  
  for device in `cat $TMP | awk '{print $4}' | sort`; do
    # fall over if we should ignore the current device
    echo $device | grep -q "/dev/tt.USB$IGNOREUSB"
    if [ $? -eq 0 ]; then
      [ $VERBOSE != "no" ] && echo -e "Skipping device on \033[1m/dev/ttyUSB$IGNOREUSB\033[0m"
      continue
    fi
    
    # else, go ahead
    array_find $device $TELOS_B && PRPLAN="$PRPLAN telosb $device " && PLATFORMS="$PLATFORMS telosb"
    array_find $device $TELOS_A && PRPLAN="$PRPLAN telosa $device " && PLATFORMS="$PLATFORMS telosa"
    array_find $device $MIB520  && PRPLAN="$PRPLAN $1 $device " && PLATFORMS="$PLATFORMS $1"
  done
  rm $TMP
  return 0
}

# compile the application's code
compile_code() {
  QUEUE=""
  for platform in `echo $@ | tr ' ' '\n' | sort | uniq`; do
    [ $VERBOSE != "no" ] && echo -e "Compile job for : \033[1m$platform\033[0m"
    make $platform 1>$LOGFILE-$platform 2>&1 &
    # push the last make command's PID to the queue
    QUEUE="$QUEUE $!"
  done
  # wait for completion
  wait $QUEUE;
  ERROR=$?
   
  # assemble logs
  for platform in `echo $@ | tr ' ' '\n' | sort | uniq`; do
    cat $LOGFILE-$platform >> $LOGFILE
    rm $LOGFILE-$platform
  done
  
  if [ $ERROR -ne 0 ]; then
    echo "Error : Compilation failed !"
    echo "----------------------------"
    cat $LOGFILE
    rm $LOGFILE
    exit 1
  else
    [ $VERBOSE != "no" ] && echo "Compilation succeeded."
    rm $LOGFILE
  fi
}

# programs motes in parallel defined by the progamming plan
# plan is to be given in <mote> <device> <mote> <device> ... form
program_motes() {
  QUEUE=""
  PLATFORM_SET=""
  ERROR=0
  tnid=$START_ID
 
  while [ $# -ne 0 ]; do
    platform=$1; device=$2; shift 2
    PLATFORM_SET="$PLATFORM_SET $platform "
    
    [ $VERBOSE != "no" ] && echo -e "Programming job for : \033[1m$platform\033[0m on \033[1m$device\033[0m with TOS_NODE_ID \033[1m$tnid\033[0m."
    case "$platform" in
      iris)
        make $platform reinstall,$tnid mib520,$device 1>$LOGFILE-$platform-$tnid 2>&1 &
        ;;
      telosa|telosb)
        make $platform reinstall,$tnid bsl,$device 1>$LOGFILE-$platform-$tnid 2>&1 &
        ;;
      *)
        [ $VERBOSE != "no" ] && echo " (UNKNOWN PLATFORM)" > $LOGFILE-$platform-$id;
        ERROR=1
        break;
        ;;
    esac
    ((tnid++))
    # push the last make command's PID to the queue
    QUEUE="$QUEUE $!"
  done
  wait $QUEUE;
  ((ERROR+=$?))
  
  # assemble logs
  tnid=$START_ID
  for platform in $PLATFORM_SET; do
    cat $LOGFILE-$platform-$tnid >> $LOGFILE
    rm $LOGFILE-$platform-$tnid
    ((tnid++))
  done
  
  if [ $ERROR -ne 0 ]; then
    echo "Error : Programming failed !"
    echo "----------------------------"
    cat $LOGFILE
    rm $LOGFILE
    exit 1
  else
    [ $VERBOSE != "no" ] && echo "Programming succeeded."
    rm $LOGFILE
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
      -q|--quiet) 
          VERBOSE=no;;
      --startid)
          shift;
          START_ID=$1;;
      -i|--ignoreusb)
          shift
          IGNOREUSB=$1;;
      --progonly)
          PROGONLY='yes';;
      --compileonly)
          COMPILEONLY='yes';;
      --) shift ; break ;;
      *)  shift ; break ;;
   esac 
   shift
done

# detect the motes connected
detect_motes $1
if [[ $? -ne 0 || $PLATFORMS = "" || $PRPLAN = "" ]]; then
  [ $VERBOSE != "no" ] && echo "Nothing to do. Quitting."
  exit 1
fi
# compile the application
if [ $PROGONLY != 'yes' ]; then
  compile_code $PLATFORMS
fi  
# program the motes
if [ $COMPILEONLY != 'yes' ]; then
  program_motes $PRPLAN
fi
exit 0
