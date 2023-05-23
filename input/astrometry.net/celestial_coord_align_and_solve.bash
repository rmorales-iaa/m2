#!/bin/bash
#------------------------------------------------------------------------------
set -x  #debug
#------------------------------------------------------------------------------
#user input with abolute path
INPUT_DIR=$1
#------------------------------------------------------------------------------
OUTPUT_DIR=$INPUT_DIR/aligned
TMP_DIR=$OUTPUT_DIR/wcs
#------------------------------------------------------------------------------
JAR_PATH=/home/rafa/proyecto/m2/deploy/
JAR=m2.jar
#------------------------------------------------------------------------------
#align 
CURRENT_PATH=$(pwd)
rm -fr $OUTPUT_DIR
cd $JAR_PATH
java -jar $JAR --align $INPUT_DIR --output-dir $OUTPUT_DIR
cd $CURRENT_PATH
#------------------------------------------------------------------------------
#solve
rm -fr $TMP_DIR
./wcs_classic_parallel_solve_fits.bash $OUTPUT_DIR $TMP_DIR 
#------------------------------------------------------------------------------
#copy the updated images
cp $TMP_DIR/*.fits $INPUT_DIR
rm -fr $TMP_DIR
rm -fr $OUTPUT_DIR
#------------------------------------------------------------------------------
#end of file
