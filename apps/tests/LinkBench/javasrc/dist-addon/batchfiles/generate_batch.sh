#!/bin/bash
# This shell script is useful for generating hundreds of benchmarks
# based on specific needs without the need of typing 1 billion words.
#
# Modify the code of main() as you like.

# Here is an example how to generate a bunch of descriptions
main() {
  A_BMARK=""
  TIME=10000
  TIMER1=(0 0 100)
  #TIMER2=(0 33 100)
  #TIMER3=(0 66 100)
  #ACK=yes
  #ACK=yes
  WAKEUP=400
  TIMES="100 500 1000 2000"
  for t in $TIMES; do

  for BMARK in `seq 100 105`; do
    TIMER1[2]=$t
    #for WAKEUP in $A_WAKEUP; do
      print_bmark >> $1
    
    done
  done
}

# Print a YAML-correct benchmark description based on env vars
print_bmark() {
  # start benchmark
  echo "---"
  # config section
  if [[ -z $TIME || -z $BMARK ]]; then
    echo "Undefined BMARK or TIME value!"
    exit 1
  fi
  
  echo -n "config: {bmark: $BMARK, time: $TIME"
  echo -n ${MOTES:+", motes: $MOTES"};
  echo -n ${RANDSTART:+", randstart: $RANDSTART"};
  echo -n ${LCHANCE:+", lchance: $LCHANCE"};
  echo "}"
  
  #timers section
  GOTTIMER=0
  if [[ -n $TIMER1 && ${#TIMER1[*]} -eq 3 ]]; then
   GOTTIMER=1
   TIMERV[0]="t1: [${TIMER1[0]}, ${TIMER1[1]}, ${TIMER1[2]}]"
  fi
  if [[ -n $TIMER2 && ${#TIMER2[*]} -eq 3 ]]; then
   GOTTIMER=1
   TIMERV[1]="t2: [${TIMER2[0]}, ${TIMER2[1]}, ${TIMER2[2]}]"
  fi
  if [[ -n $TIMER3 && ${#TIMER3[*]} -eq 3 ]]; then
   GOTTIMER=1
   TIMERV[2]="t3: [${TIMER3[0]}, ${TIMER3[1]}, ${TIMER3[2]}]"
  fi
  if [[ -n $TIMER4 && ${#TIMER4[*]} -eq 3 ]]; then
   GOTTIMER=1
   TIMERV[3]="t4: [${TIMER4[0]}, ${TIMER4[1]}, ${TIMER4[2]}]"
  fi
  if [[ $GOTTIMER -eq 1 ]]; then
    echo "timers:"
    echo ${TIMERV[0]}${TIMERV[1]}${TIMERV[2]}${TIMERV[3]} | sed 's/\]t/\]\nt/g' | sed 's/\(t[0-9]\):/ - \1:/g'
  fi

  unset GOTTIMER
  unset TIMERV
  
  # forces section
  FORCES=${BCAST}${ACK}
  echo -n ${FORCES:+"forces: "}
  FORCESV="[${BCAST:+bcast}, ${ACK:+ack}]"
  echo -n $FORCESV | sed 's:, \]:\]:g' | sed 's:\[, :\[:g' | sed 's:\[\]::g'
  echo -ne ${FORCES:+'\n'}
   
  unset FORCES
  unset FORCESV
  # wakeup section
  echo -en ${WAKEUP:+"wakeup: $WAKEUP\n"};
}

main $1



