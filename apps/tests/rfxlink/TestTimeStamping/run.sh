#!/bin/sh
if cygpath -w / >/dev/null 2>/dev/null; then
  CLASSPATH="$CLASSPATH;Jama-1.0.2.jar"
else
  CLASSPATH="$CLASSPATH:Jama-1.0.2.jar"
fi
java Analize $@
