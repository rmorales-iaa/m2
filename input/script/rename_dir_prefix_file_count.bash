#==================================================================================================
#!/bin/bash
#------------------------------------------------------------------------------
#constants
#------------------------------------------------------------------------------
ROOT_DIR=$1/
#------------------------------------------------------------------------------
DIR_FILE_PREFIX="star_"
#------------------------------------------------------------------------------
#vars
FILE_COUNT=0
DIR_COUNT=0
START_TIME=$(date +'%s')
#------------------------------------------------------------------------------
#shopt -s extglob
#set -x  #debug
#------------------------------------------------------------------------------
function process_dir {
  
  DIR=$1
  DIR_COUNT=$((DIR_COUNT+1))
  
  F_COUNT=$(find $DIR  -type f | wc -l) 
  FILE_COUNT=$((FILE_COUNT+F_COUNT))
  echo "Processing directory: '$DIR' with: $F_COUNT files "
  
  FULL_FILE=$DIR
  DIR_RAW_NAME=$(basename -- "$FULL_FILE")
  DIR_PARENT="$(dirname "$FULL_FILE")"/ #add the path divider

  NEW_DIR_NAME="$( printf "%s%04d_%s" $DIR_PARENT $F_COUNT $DIR_RAW_NAME )"
 
  mv $DIR $NEW_DIR_NAME
}
#------------------------------------------------------------------------------
function stats {
  echo "Directories processed :" $DIR_COUNT
  echo "Files processed       :" $FILE_COUNT
  echo "Elapsed time $(($(date +'%s') - $START_TIME)) seconds"
}
#------------------------------------------------------------------------------

DIR_LIST="$(find $ROOT_DIR -name 'star_*' -type d | sort)"
for DIR in $DIR_LIST; do
   process_dir $DIR
done

stats
#------------------------------------------------------------------------------
#end of file

#==================================================================================================
