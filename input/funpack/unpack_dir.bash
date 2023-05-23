#!/bin/bash
#------------------------------------------------------------------------------
#user's input
#------------------------------------------------------------------------------
ROOT_DIR=$1
#------------------------------------------------------------------------------
#constants
#------------------------------------------------------------------------------
PROGRAM_PATH=./funpack
#------------------------------------------------------------------------------
INPUT_FILE_EXTENSION=".fz"
OUTPUT_FILE_EXTENSION=".fits"
#------------------------------------------------------------------------------
#vars
FILE_COUNT=0
DIR_COUNT=0
START_TIME=$(date +'%s')
#------------------------------------------------------------------------------
function process_file {
  FILE_COUNT=$((FILE_COUNT+1))
  FULL_FILE=$1

  FILE_NAME=$(basename -- "$FULL_FILE")
  FILE_PARENT="$(dirname "$FULL_FILE")"/ #add the path divider
  FILE_EXTENSION="${FILE_NAME##*.}"
  FILE_NAME_NO_EXTENSION="${FILE_NAME%.*}"

  echo "  Processing file: " $FILE_NAME
  $PROGRAM_PATH  -O $FILE_PARENT$FILE_NAME_NO_EXTENSION$OUTPUT_FILE_EXTENSION -D $FULL_FILE
}
#------------------------------------------------------------------------------
function process_dir {
  DIR_COUNT=$((DIR_COUNT+1))
  DIR=$1
  echo "Processing directory: " $DIR
  FILE_LIST="$(find $DIR -type f -name *$INPUT_FILE_EXTENSION)" #add the asterisk
  for FILE in $FILE_LIST; do
	process_file $FILE
  done
}
#------------------------------------------------------------------------------
function stats {
  echo "Directories processed :" $DIR_COUNT
  echo "Files processed       :" $FILE_COUNT
  echo "Elapsed time $(($(date +'%s') - $START_TIME)) seconds"
}
#------------------------------------------------------------------------------
DIR_LIST="$(find $ROOT_DIR -type d)"
for DIR in $DIR_LIST; do
   process_dir $DIR
done
#------------------------------------------------------------------------------
stats
#------------------------------------------------------------------------------
#end of file
