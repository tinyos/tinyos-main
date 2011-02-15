PLATFORM=${PLATFORM:-tmote}
echo "ROM and RAM sizes:"
for prec in Second Milli 32khz ; do
  for mux in 0 1 ; do
    for alarms in 1 2 3 4 5 6 7 8; do
      echo -n "prec=${prec} mux=${mux} alarms=${alarms}"
      make ${PLATFORM} usemux,${mux} alarms,${alarms} useleds,0 useprec,${prec} \
        2>&1 | sed \
         -e '1,/compiled TestAppC to/d' \
         -e '/^msp430-objcopy/,$d' \
	 -e 's@bytes in.*$@@' \
        | paste -s -
      mv -f build/${PLATFORM}/app.c build/${PLATFORM}/app-m${mux}-a${alarms}.c >/dev/null 2>&1
    done
  done
  if [ Milli = "${prec}" ] ; then
    for alarms in 1 2 3 4 5 6 7 8; do
      echo -n "prec=${prec} timers=${alarms}"
      make ${PLATFORM} usetimer,1 alarms,${alarms} useleds,0 useprec,${prec} \
        2>&1 | sed \
         -e '1,/compiled TestAppC to/d' \
         -e '/^msp430-objcopy/,$d' \
	 -e 's@bytes in.*$@@' \
        | paste -s -
      mv -f build/${PLATFORM}/app.c build/${PLATFORM}/app-timer-a${alarms}.c >/dev/null 2>&1

    done
  fi
done

