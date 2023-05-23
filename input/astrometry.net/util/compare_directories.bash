#!/bin/bash
#--------------------------------------------
#user input
INPUT_DIR=$1
OUTPUT_DIR=$2
#--------------------------------------------
FILE_EXTENSION=.f*
#--------------------------------------------
echo "User parameters:"
echo "  Input dir        :" $INPUT_DIR
echo "  Output dir       :" $OUTPUT_DIR
echo "  File extension   :" $FILE_EXTENSION
#------------------------------------------------------------------------------
shopt -s extglob
#set -x  #debug
#------------------------------------------------------------------------------
declare -a FILE_EXTENSION_TO_REMOVE_0_ARRAY
FILE_EXTENSION_TO_REMOVE_ARRAY=(.axy .wcs .rdls .corr -indx.xyls .solved .xyls .match)
#--------------------------------------------
dropcaches_system_ctl  #clear memory cache
startTime=$(date +'%s')
#--------------------------------------------
INPUT_COUNT="$(find -L $INPUT_DIR  -maxdepth 1  -name *"$FILE_EXTENSION" -printf x | wc -c)"
OUTPUT_COUNT="$(find -L $OUTPUT_DIR -maxdepth 1  -name *"$FILE_EXTENSION" -printf x | wc -c)"
echo "---------->Input directory file count" : $INPUT_COUNT
echo "---------->Output directory file count": $OUTPUT_COUNT

if [ $INPUT_COUNT != $OUTPUT_COUNT ]
then
  FILE_1=sorted_input
  FILE_2=sorted_output
  DIFF_DIR=$OUTPUT_DIR/not_found
  DIFF_FILE=$DIFF_DIR/image_list
  
  mkdir $DIFF_DIR
  echo "WCS can not solved on:" $(( $INPUT_COUNT - $OUTPUT_COUNT )) " images. Please review the directory: '"$DIFF_DIR"'"
  find -L $INPUT_DIR -maxdepth 1 -name *"$FILE_EXTENSION" -type f -printf "%f\n" | sort > $FILE_1
  find -L $OUTPUT_DIR -maxdepth 1 -name *"$FILE_EXTENSION" -type f -printf "%f\n" | sort > $FILE_2
  comm -23 $FILE_1 $FILE_2 > $DIFF_FILE
  rm $FILE_1
  rm $FILE_2
  
  #copy the not solved images
  echo "Copying not solved files"
  while IFS='' read -r imageName || [[ -n "${imageName}" ]]; do
    cp $INPUT_DIR/$imageName $DIFF_DIR
  done < "$DIFF_FILE"
  
  echo "---------->Input and output directories has the same amount of files"
fi
#-------------------------------------------- 
echo "---------->Elapsed time: $(($(date +'%s') - $startTime))s"
dropcaches_system_ctl #clear memory cache
#--------------------------------------------
