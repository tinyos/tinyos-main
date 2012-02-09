#! /bin/bash
# Script to compile and install software in a mote. Each mote can be a Coordinator, Router, End-device or Sniffer.
# Usage ./pmote.sh <install type> <device type> <USB port number> <device address> [<depth> <address parent> <xPos> <yPos>]

PLATFORM=telosb

ZIGBEE_PATH=$TOSDIR/lib/zigbee/clusterTree
echo $ZIGBEE_PATH

APP_TEST_PATH=$TOSDIR/lib/zigbee/tests
echo $APP_TEST_PATH

PROG_DEV=bsl

if [ $# -lt 4 ]; then

	clear
	echo "Not recognized parameters!!!"
	echo "Usage : ./pmote.sh <install type> <device type> <USB port number> <device address> [<depth> <address parent> <xPos> <yPos>]"
	echo "pmote.sh i c 3 0, compile and program mote (i) as coordinator (c), on /dev/ttyUSB3, with address 0"
	echo "Installation type <Parameter>. Use c to compile only, i to install or r to reinstall." 
	read -p "Installation type : " inst_type
	echo "Please enter device type."
	echo "c - Coordinator."
	echo "r - Router."
	echo "e - End Device"
	echo "s - Sniffer"
	read -p "Device type : " device
	read -p "Please enter USB port number : " port
	read -p "Please enter device address : " initAddress
    
else
	inst=`echo $1`
	device=`echo $2`
	port=`echo $3`
	initAddress=`echo $4`
fi

# Set default PAN_ID
DEF_MAC_PANID=0xABCD
export `echo "DEF_MAC_PANID=$DEF_MAC_PANID"`

# Set default channel
DEF_CHANNEL=26
export `echo "DEF_CHANNEL=$DEF_CHANNEL"`

#set default Build dir
BUILDDIR="images/"$initAddress
export `echo "BUILDDIR=$BUILDDIR"`

# Set default device depth if used
if [ $# -gt 4 ]; then
	DEF_DEVICE_DEPTH=`echo $5`
	export `echo "DEF_DEVICE_DEPTH=$DEF_DEVICE_DEPTH"`
	echo "Device Depth: $DEF_DEVICE_DEPTH"
fi

# Set default chosen parent if used
if [ $# -gt 5 ]; then
	DEF_CHOSEN_PARENT=`echo $6`
	export `echo "DEF_CHOSEN_PARENT=$DEF_CHOSEN_PARENT"`
	echo "Chosen Parent: $DEF_CHOSEN_PARENT"
fi

# Set default X if used
if [ $# -gt 6 ]; then
	DEF_MY_X=`echo $7`
	export `echo "DEF_MY_X=$DEF_MY_X"`
	echo "My X: $DEF_MY_X"
fi

# Set default Y if used
if [ $# -gt 7 ]; then
	DEF_MY_Y=`echo $8`
	export `echo "DEF_MY_Y=$DEF_MY_Y"`
	echo "My Y: $DEF_MY_Y"
fi

device_type=""

if [ $device = 'c' ] || [ $device = 'C' ]; then
	device_type="IM_COORDINATOR=1"
	cd $APP_TEST_PATH/coordinator

elif [ $device = 'r' ] || [ $device = 'R' ]; then
	device_type="IM_ROUTER=1"
	cd $APP_TEST_PATH/router

elif [ $device = 'e' ] || [ $device = 'E' ]; then
	device_type="IM_END_DEVICE=1"
	cd $APP_TEST_PATH/end_device

elif [ $device = 's' ] || [ $device = 'S' ]; then

	cd $TOSROOT/apps/tests/tkn154/packetsniffer/
	device_type="IM_SNIFFER=1"
else
	echo "Wrong parameters"
	exit
fi

if [[ $port != ${port//[^0-9]/} ]]; then
    echo "Wrong parameters"
    echo "$port is  not an integer"
    exit
fi

port=`echo "ttyUSB"$port`
echo $port

echo $device_type
export `echo "$device_type"`

if [ $inst = 'i' ] || [ $inst = 'I' ]; then
	make clean
	make $PLATFORM install.$initAddress $PROG_DEV,/dev/$port

elif [ $inst = 'c' ] || [ $inst = 'C' ]; then
	make clean
	make $PLATFORM
	
elif [ $inst = 'r' ] || [ $inst = 'R' ]; then
	make $PLATFORM reinstall.$initAddress $PROG_DEV,/dev/$port
	
else
    echo "Wrong parameters"
    exit
fi

echo DONE!!!
