#!/bin/bash
LINKBENCH="linkbench.jar"
CP=${LINKBENCH}:${CLASSPATH}
EXEC=benchmark.cli.BenchmarkCli
if [ -f ${LINKBENCH} ]; then
  java -cp $CP $EXEC $@
else
  echo -e "No \033[1m$LINKBENCH\033[0m file found. Have you built the Java application?";
fi
