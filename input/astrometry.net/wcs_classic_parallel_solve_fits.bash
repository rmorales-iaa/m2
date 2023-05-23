#!/bin/bash
#------------------------------------------------------------------------------
shopt -s extglob
#set -x  #debug
#--------------------------------------------
#user input
INPUT_DIR=$1
OUTPUT_DIR=$2
#--------------------------------------------
FILE_EXTENSION=.f*
USER_BATCH=wcs_classic_solve_fits.bash
#--------------------------------------------
rm -fr $OUTPUT_DIR
mkdir -p $OUTPUT_DIR
#--------------------------------------------
echo "User parameters:"
echo "  Input dir        :" $INPUT_DIR
echo "  Output dir       :" $OUTPUT_DIR
echo "  File extension   :" $FILE_EXTENSION
echo "  User batch file  :" $USER_BATCH
#------------------------------------------------------------------------------
declare -a FILE_EXTENSION_TO_REMOVE_0_ARRAY
FILE_EXTENSION_TO_REMOVE_ARRAY=(.axy .wcs .rdls .corr -indx.xyls .solved .xyls .match)
#------------------------------------------------------------------------------
function delete_intermediate_files() {
  echo "---->Deleting intermediate files"
  for key in "${FILE_EXTENSION_TO_REMOVE_ARRAY[@]}"
  do
   rm -fr $INPUT_DIR/*$key
  done
}
#--------------------------------------------
echo "Parallelizating the jobs. It will take some seconds..."
#--------------------------------------------
startTime=$(date +'%s')
#--------------------------------------------
#solve files in parallel

find -L $INPUT_DIR -name *$FILE_EXTENSION  | sort -fn | parallel --bar  bash ./$USER_BATCH $OUTPUT_DIR

delete_intermediate_files
#--------------------------------------------
INPUT_COUNT="$(find -L $INPUT_DIR -maxdepth 1  -name *"$FILE_EXTENSION" -printf x | wc -c)"
OUTPUT_COUNT="$(find -L $OUTPUT_DIR -maxdepth 1  -name *"$FILE_EXTENSION" -printf x | wc -c)"
echo "---------->Input directory file count" : $INPUT_COUNT
echo "---------->Output directory file count": $OUTPUT_COUNT

if [ $INPUT_COUNT != $OUTPUT_COUNT ]
then
  FILE_1=sorted_input
  FILE_2=sorted_output
  DIFF_DIR=$OUTPUT_DIR/not_solved
  DIFF_FILE=$DIFF_DIR/image_list

  mkdir $DIFF_DIR
  echo "WCS can not solved on:" $(( $INPUT_COUNT - $OUTPUT_COUNT )) " images. Please review the directory: '"$DIFF_DIR"'"
  find -L $INPUT_DIR  -maxdepth 1 -name *"$FILE_EXTENSION" -type f -printf "%f\n" | sort > $FILE_1
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
#--------------------------------------------
#end of file
