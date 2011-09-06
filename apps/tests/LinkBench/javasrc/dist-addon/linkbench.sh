#!/bin/bash
EXEC="linkbench.jar"
if [ -f $EXEC ]; then
  java -jar $EXEC $@
else
  echo -e "No \033[1m$EXEC\033[0m file found. Have you built the Java application?";
fi
