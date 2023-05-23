#==================================================================================================
#!/bin/bash
#------------------------------------------------------------------------------
#constants
#------------------------------------------------------------------------------
ROOT_DIR=$1/

#OUTPUT_DIR=fixed_images  #using sed, file is updated

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

  echo "  Processing file: " $FILE_NAME
  RESULT=$(astfits --numhdus $ROOT_DIR/$FILE_NAME)
  
  if [[ $RESULT == "" ]]; then
    echo "Fixing: $ROOT_DIR/$FILE_NAME" 
    
    FILE_IN=$ROOT_DIR/$FILE_NAME
    FILE_OUT=$OUTPUT_DIR/$FILE_NAME
    
    #remove extra 3 bytes before image data: 8640,8641,8642
    #dd if=$FILE_IN bs=1 count=8639 of=$FILE_OUT
    #dd if=$FILE_IN bs=1 skip=8643  oflag=append conv=notrunc of=$FILE_OUT
    
    #"'Instituto De Astrofï¿½sica De Andalucï¿½a'   "(has 4 extra bytes at end, just remove it)           
    sed -i 's/\x27\x49\x6E\x73\x74\x69\x74\x75\x74\x6F\x20\x44\x65\x20\x41\x73\x74\x72\x6F\x66\xEF\xBF\xBD\x73\x69\x63\x61\x20\x44\x65\x20\x41\x6E\x64\x61\x6C\x75\x63\xEF\xBF\xBD\x61\x27\x20\x20\x20\x20/\x27\x49\x6E\x73\x74\x69\x74\x75\x74\x6F\x20\x44\x65\x20\x41\x73\x74\x72\x6F\x66\xEF\xBF\xBD\x73\x69\x63\x61\x20\x44\x65\x20\x41\x6E\x64\x61\x6C\x75\x63\xEF\xBF\xBD\x61\x27/g'  $FILE_IN


  fi  
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
rm -fr $OUTPUT_DIR
mkdir $OUTPUT_DIR

DIR_LIST="$(find $ROOT_DIR -type d)"
for DIR in $DIR_LIST; do
   process_dir $DIR
done

stats
#------------------------------------------------------------------------------
#end of file

#==================================================================================================
