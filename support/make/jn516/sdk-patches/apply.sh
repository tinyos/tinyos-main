#!/bin/sh
cd $JENNIC_SDK_DIR/
#ls
#echo "$(dirname `readlink -f $0`)/01-linkscripts_sbrk_fix.patch"
patch -p0 <$(dirname `readlink -f $0`)/01-linkscripts_sbrk_fix.patch
patch -p0 <$(dirname `readlink -f $0`)/02-sdk_jendefs-no_bool.patch

