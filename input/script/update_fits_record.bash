#==================================================================================================
#!/bin/bash
#------------------------------------------------------------------------------
#constants
#------------------------------------------------------------------------------
ROOT_DIR=$1/
#------------------------------------------------------------------------------
INPUT_FILE_EXTENSION=".fits"
#------------------------------------------------------------------------------
#vars
FILE_COUNT=0
DIR_COUNT=0
START_TIME=$(date +'%s')
#------------------------------------------------------------------------------
shopt -s extglob
#set -x  #debug
#------------------------------------------------------------------------------
function process_file {
  FILE_COUNT=$((FILE_COUNT+1))
  FULL_FILE=$1

  FILE_NAME=$(basename -- "$FULL_FILE")
  FILE_PARENT="$(dirname "$FULL_FILE")"/ #add the path divider
  FILE_EXTENSION="${FILE_NAME##*.}"
  FILE_NAME_NO_EXTENSION="${FILE_NAME%.*}"
  
  OBJECT_NAME=$(astfits --hdu 0 $ROOT_DIR/$FILE_NAME | grep '^OBJECT' | cut -d'=' -f 2 | tr -d "'" | tr -d '[:blank:]')
 
  
  OBJECT_NAME=$(echo "$OBJECT_NAME" | sed "s/Planet9a_a/Planet9a/g")
  
  echo "  Processing file: " $FILE_NAME
  astfits --hdu 0 --update=OBJECT,$OBJECT_NAME $f $ROOT_DIR/$FILE_NAME
     
}
#------------------------------------------------------------------------------
function process_dir {
  DIR_COUNT=$((DIR_COUNT+1))
  DIR=$1
  echo "Processing directory: " $DIR
  FILE_LIST=$(find $DIR -type f -name "*$INPUT_FILE_EXTENSION") #add the asterisk
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

rm -fr $OUPUT_DIR
mkdir $OUPUT_DIR

DIR_LIST="$(find $ROOT_DIR -type d | sort)"
for DIR in $DIR_LIST; do
   process_dir $DIR
done

stats
#------------------------------------------------------------------------------
#end of file

#==================================================================================================
